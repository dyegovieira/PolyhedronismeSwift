//
// PolyhedronismeSwift
// DefaultPolyhedronGenerator.swift
//
// Default polyhedron generator service implementation for Conway notation processing
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultPolyhedronGenerator: PolyhedronGeneratorProtocol {
    public let baseRegistry: BaseRegistry
    public let operatorRegistry: OperatorRegistry
    private let parser: NotationParser
    private let operations: PolyhedronOperationsProtocol
    private let edgeCalculator: EdgeCalculator
    private let operatorFactory: OperatorFactory
    
    public init(
        baseRegistry: BaseRegistry,
        operatorRegistry: OperatorRegistry,
        parser: NotationParser = DefaultNotationParser(),
        operations: PolyhedronOperationsProtocol = DefaultPolyhedronOperations(),
        edgeCalculator: EdgeCalculator = DefaultEdgeCalculator(),
        operatorFactory: OperatorFactory
    ) {
        self.baseRegistry = baseRegistry
        self.operatorRegistry = operatorRegistry
        self.parser = parser
        self.operations = operations
        self.edgeCalculator = edgeCalculator
        self.operatorFactory = operatorFactory
    }
    
    public func generate(notation: String) async throws -> PolyhedronModel {
        let configuration = if let requestConfiguration = ParallelismRequestContext.configuration {
            requestConfiguration
        } else {
            await PolyhedronismeSwiftConfiguration.shared.snapshot()
        }
        return try await ParallelismRequestContext.$configuration.withValue(configuration) {
            try await generateAsync(notation: notation)
        }
    }
    
    public func stream(notation: String) -> AsyncThrowingStream<GenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            let producer = Task(priority: .userInitiated) {
                do {
                    let configuration = if let requestConfiguration = ParallelismRequestContext.configuration {
                        requestConfiguration
                    } else {
                        await PolyhedronismeSwiftConfiguration.shared.snapshot()
                    }
                    let model = try await ParallelismRequestContext.$configuration.withValue(configuration) {
                        try await self.generateAsync(notation: notation, eventHandler: { event in
                            switch continuation.yield(event) {
                            case .terminated:
                                return false
                            case .enqueued, .dropped:
                                return true
                            @unknown default:
                                return false
                            }
                        })
                    }
                    try Task.checkCancellation()
                    let polyhedron = Polyhedron(model, recipe: notation)
                    guard case .terminated = continuation.yield(.completed(polyhedron)) else {
                        continuation.finish()
                        return
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                producer.cancel()
            }
        }
    }
    
    private func generateAsync(
        notation: String,
        eventHandler: ((GenerationEvent) -> Bool)? = nil
    ) async throws -> PolyhedronModel {
        try Task.checkCancellation()
        try emit(.stageStarted(.parsing), to: eventHandler)
        let ast = try parser.parse(notation)
        try Task.checkCancellation()
        try emit(.stageCompleted(.parsing), to: eventHandler)
        let firstOp = ast.base
        
        var polyModel: PolyhedronModel
        
        try emit(.stageStarted(.base(firstOp.identifier)), to: eventHandler)
        if let base = baseRegistry.getBase(for: firstOp.identifier) {
            do {
                polyModel = try await base.generate()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
            }
        } else if firstOp.identifier == "P" || firstOp.identifier == "A" || firstOp.identifier == "Y" {
            let n = try ParameterExtractor.extractIntParameter(
                firstOp.parameters,
                at: 0,
                default: 3,
                min: 3,
                parameterName: "\(firstOp.identifier) base parameter n"
            )
            if let prismGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: PrismParameters.self) as? PrismGenerator {
                do {
                    polyModel = try await prismGen.generate(parameters: PrismParameters(n: n))
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else if let antiprismGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: AntiprismParameters.self) as? AntiprismGenerator {
                do {
                    polyModel = try await antiprismGen.generate(parameters: AntiprismParameters(n: n))
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else if let pyramidGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: PyramidParameters.self) as? PyramidGenerator {
                do {
                    polyModel = try await pyramidGen.generate(parameters: PyramidParameters(n: n))
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else {
                throw GenerationError.parsingFailed(.unknownBase(firstOp.identifier))
            }
        } else if firstOp.identifier == "U" || firstOp.identifier == "V" {
            let n = try ParameterExtractor.extractIntParameter(
                firstOp.parameters,
                at: 0,
                default: 3,
                min: 2,
                parameterName: "\(firstOp.identifier) base parameter n"
            )
            if let cupolaGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: CupolaParameters.self) as? CupolaGenerator {
                do {
                    polyModel = try await cupolaGen.generate(parameters: CupolaParameters(n: n, alpha: nil, height: nil))
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else if let anticupolaGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: AnticupolaParameters.self) as? AnticupolaGenerator {
                do {
                    polyModel = try await anticupolaGen.generate(parameters: AnticupolaParameters(n: n, alpha: nil, height: nil))
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else {
                throw GenerationError.parsingFailed(.unknownBase(firstOp.identifier))
            }
        } else {
            throw GenerationError.parsingFailed(.unknownBase(firstOp.identifier))
        }
        try Task.checkCancellation()
        try emit(.stageCompleted(.base(firstOp.identifier)), to: eventHandler)
        try emit(.metrics(PolyhedronMetricsSnapshot(model: polyModel, stageDescription: "Base \(firstOp.identifier)")), to: eventHandler)
        
        for op in ast.operators {
            try Task.checkCancellation()
            try emit(.stageStarted(.operator(op.identifier)), to: eventHandler)
            do {
                let operatorApplicable = try await operatorFactory.createOperator(for: op)
                polyModel = try await operatorApplicable.apply(to: polyModel)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw GenerationError.operatorApplicationFailed(op.identifier, underlying: error)
            }
            try Task.checkCancellation()
            try emit(.stageCompleted(.operator(op.identifier)), to: eventHandler)
            try emit(.metrics(PolyhedronMetricsSnapshot(model: polyModel, stageDescription: "Operator \(op.identifier)")), to: eventHandler)
        }
        
        try emit(.stageStarted(.canonicalize), to: eventHandler)
        var workingModel = polyModel
        workingModel = await operations.recenter(workingModel, edgeCalculator: edgeCalculator)
        workingModel = operations.rescale(workingModel)
        try Task.checkCancellation()
        try emit(.stageCompleted(.canonicalize), to: eventHandler)
        try emit(.metrics(PolyhedronMetricsSnapshot(model: workingModel, stageDescription: "Canonicalize")), to: eventHandler)
        
        return workingModel
    }

    private func emit(
        _ event: GenerationEvent,
        to eventHandler: ((GenerationEvent) -> Bool)?
    ) throws {
        guard eventHandler?(event) ?? true else {
            throw CancellationError()
        }
    }
}
