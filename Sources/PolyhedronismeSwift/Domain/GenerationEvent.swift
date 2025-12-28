//
// PolyhedronismeSwift
// GenerationEvent.swift
//
// GenerationEvent domain model for polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-17
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public enum GenerationStage: Sendable, Equatable {
    case parsing
    case base(String)
    case `operator`(String)
    case canonicalize
    
    public var description: String {
        switch self {
        case .parsing:
            return "parsing"
        case .base(let id):
            return "base \(id)"
        case .operator(let id):
            return "operator \(id)"
        case .canonicalize:
            return "canonicalize"
        }
    }
}

public struct PolyhedronMetricsSnapshot: Sendable {
    public let name: String
    public let vertexCount: Int
    public let faceCount: Int
    public let stageDescription: String
    
    public init(model: PolyhedronModel, stageDescription: String) {
        self.name = model.name
        self.vertexCount = model.vertices.count
        self.faceCount = model.faces.count
        self.stageDescription = stageDescription
    }
}

public enum GenerationEvent: Sendable {
    case stageStarted(GenerationStage)
    case stageCompleted(GenerationStage)
    case metrics(PolyhedronMetricsSnapshot)
    case completed(Polyhedron)
}

