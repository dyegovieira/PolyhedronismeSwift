//
// PolyhedronismeSwift
// PolyhedronError.swift
//
// Error types for polyhedron operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public enum PolyhedronError: Error, Sendable, LocalizedError {
    case invalidPolyhedron(String)
    case invalidVertex(Int)
    case invalidFace(Int)
    case emptyPolyhedron
    case invalidOperation(String)
    case internalError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPolyhedron(let reason):
            return "Invalid polyhedron: \(reason)"
        case .invalidVertex(let index):
            return "Invalid vertex index: \(index)"
        case .invalidFace(let index):
            return "Invalid face at index \(index): must have at least 3 vertices"
        case .emptyPolyhedron:
            return "Polyhedron has no vertices"
        case .invalidOperation(let operation):
            return "Invalid operation: \(operation)"
        case .internalError(let message):
            return "Internal error: \(message)"
        }
    }
}

public enum OperatorError: Error, Sendable, LocalizedError {
    case unknownOperator(String)
    case invalidParameters(String, operator: String)
    case operationFailed(String, underlying: Error)
    
    public var errorDescription: String? {
        switch self {
        case .unknownOperator(let op):
            return "Unknown operator: '\(op)'"
        case .invalidParameters(let details, let op):
            return "Invalid parameters for operator '\(op)': \(details)"
        case .operationFailed(let op, let underlying):
            return "Operation '\(op)' failed: \(underlying.localizedDescription)"
        }
    }
}

public enum GenerationError: Error, Sendable, LocalizedError {
    case parsingFailed(ParseError)
    case baseGenerationFailed(String, underlying: Error)
    case operatorApplicationFailed(String, underlying: Error)
    case canonicalizationFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .parsingFailed(let parseError):
            return "Parsing failed: \(parseError.localizedDescription)"
        case .baseGenerationFailed(let base, let underlying):
            return "Base generation failed for '\(base)': \(underlying.localizedDescription)"
        case .operatorApplicationFailed(let op, let underlying):
            return "Operator '\(op)' application failed: \(underlying.localizedDescription)"
        case .canonicalizationFailed(let underlying):
            return "Canonicalization failed: \(underlying.localizedDescription)"
        }
    }
}

