//
// PolyhedronismeSwift
// MetalError.swift
//
// Error types for Metal GPU operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public enum MetalError: Error, Sendable, LocalizedError {
    case deviceNotFound
    case libraryNotFound
    case functionNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Metal device not found"
        case .libraryNotFound:
            return "Metal library not found"
        case .functionNotFound(let name):
            return "Metal function '\(name)' not found"
        }
    }
}

