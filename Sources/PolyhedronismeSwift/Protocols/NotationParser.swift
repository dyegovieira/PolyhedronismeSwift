//
// PolyhedronismeSwift
// NotationParser.swift
//
// Protocol definition for NotationParser in Conway notation parsing
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol NotationParser: Sendable {
    func parse(_ notation: String) throws -> OperatorAST
}

internal struct OperatorAST: Sendable {
    internal let base: BaseOperation
    internal let operators: [OperatorOperation]
    
    internal init(base: BaseOperation, operators: [OperatorOperation]) {
        self.base = base
        self.operators = operators
    }
}

internal struct BaseOperation: Sendable {
    internal let identifier: String
    internal let parameters: [SendableParameter]
    
    internal init(identifier: String, parameters: [SendableParameter] = []) {
        self.identifier = identifier
        self.parameters = parameters
    }
}

internal struct OperatorOperation: Sendable {
    internal let identifier: String
    internal let parameters: [SendableParameter]
    
    internal init(identifier: String, parameters: [SendableParameter] = []) {
        self.identifier = identifier
        self.parameters = parameters
    }
}

internal enum SendableParameter: Sendable {
    case int(Int)
    case double(Double)
    case string(String)
    

}

