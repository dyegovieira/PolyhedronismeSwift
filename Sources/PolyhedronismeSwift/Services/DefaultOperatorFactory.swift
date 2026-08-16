//
// PolyhedronismeSwift
// DefaultOperatorFactory.swift
//
// Default operator factory service implementation for polyhedral operator creation
//
// Created by Dyego Vieira de Paula on 2025-11-22
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultOperatorFactory: OperatorFactory {
    private let operatorRegistry: OperatorRegistry
    private let metalExecutor: MetalExecutor
    
    internal init(
        operatorRegistry: OperatorRegistry,
        metalExecutor: MetalExecutor? = nil
    ) {
        self.operatorRegistry = operatorRegistry
        self.metalExecutor = metalExecutor ?? MetalExecutor()
    }
    
    func createOperator(for operation: OperatorOperation) async throws -> any PolyhedronOperatorApplicable {
        switch operation.identifier {
        case "k":
            return try await createKisOperator(parameters: operation.parameters)
        case "r":
            return try await createReflectOperator()
        case "d":
            return try await createDualOperator()
        case "a":
            return try await createAmboOperator()
        case "u":
            return try await createTrisubOperator(parameters: operation.parameters)
        default:
            return try await createGenericOperator(identifier: operation.identifier)
        }
    }
    
    private func createKisOperator(parameters: [SendableParameter]) async throws -> any PolyhedronOperatorApplicable {
        let n = try ParameterExtractor.extractIntParameter(
            parameters,
            at: 0,
            default: 0,
            min: 0,
            parameterName: "kis operator n parameter"
        )
        let apexDist = try ParameterExtractor.extractDoubleParameter(
            parameters,
            at: 1,
            default: 0.1,
            min: 0.0,
            parameterName: "kis operator apexDistance parameter"
        )
        
        let params = KisParameters(n: n, apexDistance: apexDist)
        let cpuKis = KisOperator()
        
        let metalKis = MetalKisOperator(executor: metalExecutor)
        let fallback = MetalFallbackParameterizedOperator(
            metalOperator: metalKis,
            cpuFallback: cpuKis,
            parameters: params
        )
        return AnyOperatorApplicable(fallback)
    }
    
    private func createReflectOperator() async throws -> any PolyhedronOperatorApplicable {
        let cpuReflect = ReflectOperator()
        
        let metalReflect = MetalReflectOperator(executor: metalExecutor)
        let fallback = MetalFallbackOperator(metalOperator: metalReflect, cpuFallback: cpuReflect)
        return AnyOperatorApplicable(fallback)
    }
    
    private func createDualOperator() async throws -> any PolyhedronOperatorApplicable {
        let cpuDual = DualOperator()
        let metalDual = MetalDualOperator(executor: metalExecutor)
        return AnyOperatorApplicable(
            MetalFallbackOperator(metalOperator: metalDual, cpuFallback: cpuDual)
        )
    }
    
    private func createAmboOperator() async throws -> any PolyhedronOperatorApplicable {
        let cpuAmbo = AmboOperator()

        let metalAmbo = MetalAmboOperator(executor: metalExecutor)
        let fallback = MetalFallbackOperator(metalOperator: metalAmbo, cpuFallback: cpuAmbo)
        return AnyOperatorApplicable(fallback)
    }
    
    private func createTrisubOperator(parameters: [SendableParameter]) async throws -> any PolyhedronOperatorApplicable {
        let n = try ParameterExtractor.extractIntParameter(
            parameters,
            at: 0,
            default: 2,
            min: 2,
            parameterName: "trisub operator n parameter"
        )
        
        let params = TrisubParameters(n: n)
        let trisubOp = TrisubOperator()
        return AnyOperatorApplicable(trisubOp, parameters: params)
    }
    
    private func createGenericOperator(identifier: String) async throws -> any PolyhedronOperatorApplicable {
        guard let op = operatorRegistry.getOperator(for: identifier) else {
            throw GenerationError.parsingFailed(.unknownOperator(identifier))
        }
        return AnyOperatorApplicable(op)
    }
}
