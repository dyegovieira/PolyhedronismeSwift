//
// PolyhedronismeSwift
// MetalFallbackOperator.swift
//
// Metal fallback operator service for graceful GPU-to-CPU degradation
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

/// Wrapper that attempts to use Metal operator but falls back to CPU on errors
internal struct MetalFallbackOperator<MetalOp: PolyhedronOperator, CPUOp: PolyhedronOperator>: PolyhedronOperatorApplicable {
    private let metalOperator: MetalOp
    private let cpuFallback: CPUOp
    
    init(metalOperator: MetalOp, cpuFallback: CPUOp) {
        self.metalOperator = metalOperator
        self.cpuFallback = cpuFallback
    }
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        do {
            return try await metalOperator.apply(to: polyhedron)
        } catch is MetalError {
            // Fall back to CPU on any Metal error
            return try await cpuFallback.apply(to: polyhedron)
        }
    }
}

/// Wrapper for parameterized operators that attempts Metal but falls back to CPU
internal struct MetalFallbackParameterizedOperator<MetalOp: ParameterizedPolyhedronOperator, CPUOp: ParameterizedPolyhedronOperator>: PolyhedronOperatorApplicable where MetalOp.Parameters == CPUOp.Parameters, MetalOp.Parameters: Sendable {
    private let metalOperator: MetalOp
    private let cpuFallback: CPUOp
    private let parameters: MetalOp.Parameters
    
    init(metalOperator: MetalOp, cpuFallback: CPUOp, parameters: MetalOp.Parameters) {
        self.metalOperator = metalOperator
        self.cpuFallback = cpuFallback
        self.parameters = parameters
    }
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        do {
            return try await metalOperator.apply(to: polyhedron, parameters: parameters)
        } catch is MetalError {
            // Fall back to CPU on any Metal error
            return try await cpuFallback.apply(to: polyhedron, parameters: parameters)
        }
    }
}

