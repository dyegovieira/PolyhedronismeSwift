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
    case unavailable(capability: String)
    case resourceCreation(String)
    case pipelineCreation(String)
    case commandFailure(String?)
    case timeout
    case deviceNotFound
    case libraryNotFound
    case functionNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .unavailable(let capability):
            return "Metal capability unavailable: \(capability)"
        case .resourceCreation(let resource):
            return "Metal resource creation failed: \(resource)"
        case .pipelineCreation(let pipeline):
            return "Metal pipeline creation failed: \(pipeline)"
        case .commandFailure(let message):
            return "Metal command failed: \(message ?? "unknown error")"
        case .timeout:
            return "Metal command timed out"
        case .deviceNotFound:
            return "Metal device not found"
        case .libraryNotFound:
            return "Metal library not found"
        case .functionNotFound(let name):
            return "Metal function '\(name)' not found"
        }
    }
}
