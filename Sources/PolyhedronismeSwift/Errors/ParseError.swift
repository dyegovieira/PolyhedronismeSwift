//
// PolyhedronismeSwift
// ParseError.swift
//
// Error types for Conway notation parsing operations
//
// Created by Dyego Vieira de Paula on 2025-11-22
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public enum ParseError: Error, Sendable, LocalizedError {
    case invalidNotation(String)
    case unknownOperator(String)
    case unknownBase(String)
    case invalidParameters(String)
    case emptyNotation
    case invalidParameterType(String, expected: String, actual: String)
    case parameterOutOfRange(String, value: Int, min: Int, max: Int?)
    case invalidRegexPattern(String, underlying: Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidNotation(let notation):
            return "Invalid notation: '\(notation)'"
        case .unknownOperator(let op):
            return "Unknown operator: '\(op)'"
        case .unknownBase(let base):
            return "Unknown base: '\(base)'"
        case .invalidParameters(let details):
            return "Invalid parameters: \(details)"
        case .emptyNotation:
            return "Empty notation string"
        case .invalidParameterType(let param, let expected, let actual):
            return "Invalid parameter type for \(param): expected \(expected), got \(actual)"
        case .parameterOutOfRange(let param, let value, let min, let max):
            let maxStr = max.map { " and ≤\($0)" } ?? ""
            return "Parameter \(param) value \(value) is out of range (must be ≥\(min)\(maxStr))"
        case .invalidRegexPattern(let pattern, let underlying):
            return "Invalid regex pattern '\(pattern)': \(underlying.localizedDescription)"
        }
    }
}

