//
// PolyhedronismeSwift
// PolyhedronismeSwiftProtocol.swift
//
// Protocol definition for PolyhedronismeSwiftProtocol in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public protocol PolyhedronismeSwiftProtocol {
    func generate(recipe: String) async throws -> Polyhedron
    func stream(recipe: String) -> AsyncThrowingStream<GenerationEvent, Error>
}

