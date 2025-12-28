//
// PolyhedronismeSwift
// PolyhedronCanonicalizer.swift
//
// Protocol definition for PolyhedronCanonicalizer in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol PolyhedronCanonicalizer: Sendable {
    func adjust(_ polyhedron: Polyhedron, iterations: Int) async -> Polyhedron
    func canonicalize(_ polyhedron: Polyhedron, iterations: Int) async -> Polyhedron
}

