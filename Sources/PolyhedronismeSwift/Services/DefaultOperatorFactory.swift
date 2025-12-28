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
    private let metalConfig: MetalConfiguration
    private let pipelineFactory: ComputePipelineFactory
    
    internal init(
        operatorRegistry: OperatorRegistry,
        metalConfig: MetalConfiguration,
        pipelineFactory: ComputePipelineFactory
    ) {
        self.operatorRegistry = operatorRegistry
        self.metalConfig = metalConfig
        self.pipelineFactory = pipelineFactory
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
        
        if let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) {
            let fallback = MetalFallbackParameterizedOperator(metalOperator: metalKis, cpuFallback: cpuKis, parameters: params)
            // Fallback already has parameters, so use non-parameterized initializer
            return AnyOperatorApplicable(fallback)
        } else {
            return AnyOperatorApplicable(cpuKis, parameters: params)
        }
    }
    
    private func createReflectOperator() async throws -> any PolyhedronOperatorApplicable {
        let cpuReflect = ReflectOperator()
        
        if let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) {
            let fallback = MetalFallbackOperator(metalOperator: metalReflect, cpuFallback: cpuReflect)
            return AnyOperatorApplicable(fallback)
        } else {
            return AnyOperatorApplicable(cpuReflect)
        }
    }
    
    private func createDualOperator() async throws -> any PolyhedronOperatorApplicable {
        let cpuDual = DualOperator()
        
        if let metalDual = MetalDualOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) {
            let fallback = MetalFallbackOperator(metalOperator: metalDual, cpuFallback: cpuDual)
            return AnyOperatorApplicable(fallback)
        } else {
            return AnyOperatorApplicable(cpuDual)
        }
    }
    
    private func createAmboOperator() async throws -> any PolyhedronOperatorApplicable {
        let cpuAmbo = AmboOperator()
        
        if let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) {
            let fallback = MetalFallbackOperator(metalOperator: metalAmbo, cpuFallback: cpuAmbo)
            return AnyOperatorApplicable(fallback)
        } else {
            return AnyOperatorApplicable(cpuAmbo)
        }
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

