//
// PolyhedronismeSwift
// ParameterizedOperatorWrapper.swift
//
// Parameterized operator wrapper registry for managing typed operators
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct ParameterizedOperatorWrapper<OP: ParameterizedPolyhedronOperator>: PolyhedronOperator where OP.Parameters: Sendable {
    private let parameterizedOperator: OP
    private let defaultParameters: OP.Parameters
    public let identifier: String
    
    public init(
        _ op: OP,
        withDefaultParameters params: OP.Parameters
    ) {
        self.parameterizedOperator = op
        self.defaultParameters = params
        self.identifier = op.identifier
    }
    
    public func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        return try await parameterizedOperator.apply(to: polyhedron, parameters: defaultParameters)
    }
}

