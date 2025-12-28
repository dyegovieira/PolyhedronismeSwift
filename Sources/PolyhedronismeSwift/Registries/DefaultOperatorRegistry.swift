//
// PolyhedronismeSwift
// DefaultOperatorRegistry.swift
//
// Operator registry for managing polyhedral operators
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultOperatorRegistry: OperatorRegistry {
    private let operators: [String: PolyhedronOperator]
    
    public init() {
        self.operators = [:]
    }
    
    public init(operators: [String: PolyhedronOperator]) {
        self.operators = operators
    }
    
    public func getOperator(for identifier: String) -> PolyhedronOperator? {
        operators[identifier]
    }
    
    public func allOperators() -> [String: PolyhedronOperator] {
        operators
    }
}

