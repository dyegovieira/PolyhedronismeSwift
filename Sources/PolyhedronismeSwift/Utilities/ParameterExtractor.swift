//
// PolyhedronismeSwift
// ParameterExtractor.swift
//
// Parameter extractor utility for parsing operator parameters
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal enum ParameterExtractor {

    
    public static func extractIntParameter(
        _ args: [SendableParameter],
        at index: Int,
        default defaultValue: Int? = nil,
        min: Int? = nil,
        max: Int? = nil,
        parameterName: String? = nil
    ) throws -> Int {
        let paramName = parameterName ?? "parameter at index \(index)"
        
        guard index < args.count else {
            if let defaultValue = defaultValue {
                return defaultValue
            }
            throw ParseError.invalidParameters("Missing \(paramName)")
        }
        
        guard case .int(let value) = args[index] else {
            let actualType: String
            switch args[index] {
            case .int: actualType = "Int"
            case .double: actualType = "Double"
            case .string: actualType = "String"
            }
            throw ParseError.invalidParameterType(paramName, expected: "Int", actual: actualType)
        }
        
        if let min = min, value < min {
            throw ParseError.parameterOutOfRange(paramName, value: value, min: min, max: max)
        }
        
        if let max = max, value > max {
            throw ParseError.parameterOutOfRange(paramName, value: value, min: min ?? Int.min, max: max)
        }
        
        return value
    }
    
    public static func extractDoubleParameter(
        _ args: [SendableParameter],
        at index: Int,
        default defaultValue: Double? = nil,
        min: Double? = nil,
        max: Double? = nil,
        parameterName: String? = nil
    ) throws -> Double {
        let paramName = parameterName ?? "parameter at index \(index)"
        
        guard index < args.count else {
            if let defaultValue = defaultValue {
                return defaultValue
            }
            throw ParseError.invalidParameters("Missing \(paramName)")
        }
        
        guard case .double(let value) = args[index] else {
            let actualType: String
            switch args[index] {
            case .int: actualType = "Int"
            case .double: actualType = "Double"
            case .string: actualType = "String"
            }
            throw ParseError.invalidParameterType(paramName, expected: "Double", actual: actualType)
        }
        
        if let min = min, value < min {
            let maxStr = max.map { " and ≤\($0)" } ?? ""
            throw ParseError.invalidParameters("\(paramName) value \(value) is out of range (must be ≥\(min)\(maxStr))")
        }
        
        if let max = max, value > max {
            let minStr = min.map { "≥\($0) and " } ?? ""
            throw ParseError.invalidParameters("\(paramName) value \(value) is out of range (must be \(minStr)≤\(max))")
        }
        
        return value
    }
}

