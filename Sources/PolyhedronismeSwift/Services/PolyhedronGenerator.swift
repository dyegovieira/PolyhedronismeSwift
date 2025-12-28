//
// PolyhedronismeSwift
// PolyhedronGenerator.swift
//
// Polyhedron generator service for recipe-based generation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol PolyhedronGeneratorProtocol: Sendable {
    var baseRegistry: BaseRegistry { get }
    var operatorRegistry: OperatorRegistry { get }
    func generate(notation: String) async throws -> PolyhedronModel
    func stream(notation: String) -> AsyncThrowingStream<GenerationEvent, Error>
}

