//
// PolyhedronismeSwift
// PolyhedronExporter.swift
//
// Protocol definition for PolyhedronExporter in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol PolyhedronExporter: Sendable {
    func export(_ polyhedron: PolyhedronModel) async throws -> String
}

