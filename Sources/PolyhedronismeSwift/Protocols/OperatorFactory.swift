//
// PolyhedronismeSwift
// OperatorFactory.swift
//
// Protocol definition for OperatorFactory in polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-22
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol OperatorFactory: Sendable {
    func createOperator(
        for operation: OperatorOperation
    ) async throws -> any PolyhedronOperatorApplicable
}

internal protocol PolyhedronOperatorApplicable: Sendable {
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel
}

