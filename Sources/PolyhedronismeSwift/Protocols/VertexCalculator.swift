//
// PolyhedronismeSwift
// VertexCalculator.swift
//
// Protocol definition for VertexCalculator in polyhedral calculations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol VertexCalculator: Sendable {
    func calculateCentroid(of vertices: [Vec3]) -> Vec3
}

