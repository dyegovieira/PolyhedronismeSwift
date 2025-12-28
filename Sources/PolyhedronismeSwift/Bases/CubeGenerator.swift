//
// PolyhedronismeSwift
// CubeGenerator.swift
//
// Cube base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct CubeGenerator: BasePolyhedronGenerator {
    public let identifier: String = "C"
    
    public init() {}
    
    public func generate() async throws -> PolyhedronModel {
        return PolyhedronModel(
            vertices: [
                [0.707, 0.707, 0.707],
                [-0.707, 0.707, 0.707],
                [-0.707, -0.707, 0.707],
                [0.707, -0.707, 0.707],
                [0.707, -0.707, -0.707],
                [0.707, 0.707, -0.707],
                [-0.707, 0.707, -0.707],
                [-0.707, -0.707, -0.707]
            ],
            faces: [
                [3, 0, 1, 2],
                [3, 4, 5, 0],
                [0, 5, 6, 1],
                [1, 6, 7, 2],
                [2, 7, 4, 3],
                [5, 4, 7, 6]
            ],
            name: "C",
            faceClasses: []
        )
    }
}

