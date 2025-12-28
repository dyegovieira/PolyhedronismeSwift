//
// PolyhedronismeSwift
// EdgeCalculator.swift
//
// Protocol definition for EdgeCalculator in polyhedral calculations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol EdgeCalculator: Sendable {
    func calculateEdges(from polyhedron: PolyhedronModel) async -> [[Int]]
    func faceToEdges(_ face: Face) -> [[Int]]
}

