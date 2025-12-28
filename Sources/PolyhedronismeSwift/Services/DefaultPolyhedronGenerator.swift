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
        try await Task.detached(priority: .userInitiated) {
            try await self.generateAsync(notation: notation)
        }.value
    }
    
    public func stream(notation: String) -> AsyncThrowingStream<GenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            Task(priority: .userInitiated) {
                do {
                    let model = try await self.generateAsync(
                        notation: notation,
                        eventHandler: { continuation.yield($0) }
                    )
                    let polyhedron = Polyhedron(model, recipe: notation)
                    continuation.yield(.completed(polyhedron))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func generateAsync(
        notation: String,
        eventHandler: ((GenerationEvent) -> Void)? = nil
    ) async throws -> PolyhedronModel {
        eventHandler?(.stageStarted(.parsing))
        let ast = try parser.parse(notation)
        eventHandler?(.stageCompleted(.parsing))
        let firstOp = ast.base
        
        var polyModel: PolyhedronModel
        
        eventHandler?(.stageStarted(.base(firstOp.identifier)))
        if let base = baseRegistry.getBase(for: firstOp.identifier) {
            do {
                polyModel = try await base.generate()
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
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else if let antiprismGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: AntiprismParameters.self) as? AntiprismGenerator {
                do {
                    polyModel = try await antiprismGen.generate(parameters: AntiprismParameters(n: n))
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else if let pyramidGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: PyramidParameters.self) as? PyramidGenerator {
                do {
                    polyModel = try await pyramidGen.generate(parameters: PyramidParameters(n: n))
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
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else if let anticupolaGen = baseRegistry.getParameterizedBase(for: firstOp.identifier, as: AnticupolaParameters.self) as? AnticupolaGenerator {
                do {
                    polyModel = try await anticupolaGen.generate(parameters: AnticupolaParameters(n: n, alpha: nil, height: nil))
                } catch {
                    throw GenerationError.baseGenerationFailed(firstOp.identifier, underlying: error)
                }
            } else {
                throw GenerationError.parsingFailed(.unknownBase(firstOp.identifier))
            }
        } else {
            throw GenerationError.parsingFailed(.unknownBase(firstOp.identifier))
        }
        eventHandler?(.stageCompleted(.base(firstOp.identifier)))
        eventHandler?(.metrics(PolyhedronMetricsSnapshot(model: polyModel, stageDescription: "Base \(firstOp.identifier)")))
        
        for op in ast.operators {
            eventHandler?(.stageStarted(.operator(op.identifier)))
            do {
                let operatorApplicable = try await operatorFactory.createOperator(for: op)
                polyModel = try await operatorApplicable.apply(to: polyModel)
            } catch {
                throw GenerationError.operatorApplicationFailed(op.identifier, underlying: error)
            }
            eventHandler?(.stageCompleted(.operator(op.identifier)))
            eventHandler?(.metrics(PolyhedronMetricsSnapshot(model: polyModel, stageDescription: "Operator \(op.identifier)")))
        }
        
        eventHandler?(.stageStarted(.canonicalize))
        var workingModel = polyModel
        workingModel = await operations.recenter(workingModel, edgeCalculator: edgeCalculator)
        workingModel = operations.rescale(workingModel)
        eventHandler?(.stageCompleted(.canonicalize))
        eventHandler?(.metrics(PolyhedronMetricsSnapshot(model: workingModel, stageDescription: "Canonicalize")))
        
        return workingModel
    }
}

