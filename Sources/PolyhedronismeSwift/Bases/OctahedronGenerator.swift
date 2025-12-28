//
// PolyhedronismeSwift
// OctahedronGenerator.swift
//
// Octahedron base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct OctahedronGenerator: BasePolyhedronGenerator {
    public let identifier: String = "O"
    
    public init() {}
    
    public func generate() async throws -> PolyhedronModel {
        return PolyhedronModel(
            vertices: [
                [0, 0, 1.414],
                [1.414, 0, 0],
                [0, 1.414, 0],
                [-1.414, 0, 0],
                [0, -1.414, 0],
                [0, 0, -1.414]
            ],
            faces: [
                [0, 1, 2],
                [0, 2, 3],
                [0, 3, 4],
                [0, 4, 1],
                [1, 4, 5],
                [1, 5, 2],
                [2, 5, 3],
                [3, 5, 4]
            ],
            name: "O",
            faceClasses: []
        )
    }
}

