//
// PolyhedronismeSwift
// PolyhedronOperator.swift
//
// Protocol definition for PolyhedronOperator in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol PolyhedronOperator: Sendable {
    var identifier: String { get }
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel
}

internal protocol ParameterizedPolyhedronOperator: Sendable {
    associatedtype Parameters
    var identifier: String { get }
    func apply(to polyhedron: PolyhedronModel, parameters: Parameters) async throws -> PolyhedronModel
}

