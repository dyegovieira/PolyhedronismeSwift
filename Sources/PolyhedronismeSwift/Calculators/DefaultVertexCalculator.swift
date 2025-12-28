//
// PolyhedronismeSwift
// DefaultVertexCalculator.swift
//
// Vertex calculator for computing vertex positions and properties
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultVertexCalculator: VertexCalculator {
    public init() {}
    
    public func calculateCentroid(of vertices: [Vec3]) -> Vec3 {
        GeometryUtils.calculateCentroid(vertices)
    }
}

