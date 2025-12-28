//
// PolyhedronismeSwift
// AnyOperatorApplicable.swift
//
// Type-erased operator applicator service for dynamic operator application
//
// Created by Dyego Vieira de Paula on 2025-11-22
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct AnyOperatorApplicable: PolyhedronOperatorApplicable {
    private let _apply: @Sendable (PolyhedronModel) async throws -> PolyhedronModel
    
    init<Op: PolyhedronOperator>(_ operator: Op) {
        _apply = { try await `operator`.apply(to: $0) }
    }
    
    init<Op: ParameterizedPolyhedronOperator>(
        _ operator: Op,
        parameters: Op.Parameters
    ) where Op.Parameters: Sendable {
        _apply = { try await `operator`.apply(to: $0, parameters: parameters) }
    }
    
    init<Op: PolyhedronOperatorApplicable>(_ operator: Op) {
        _apply = { try await `operator`.apply(to: $0) }
    }
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        try await _apply(polyhedron)
    }
}

