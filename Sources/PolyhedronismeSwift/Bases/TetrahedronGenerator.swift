//
// PolyhedronismeSwift
// TetrahedronGenerator.swift
//
// Tetrahedron base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct TetrahedronGenerator: BasePolyhedronGenerator {
    public let identifier: String = "T"
    
    public init() {}
    
    public func generate() async throws -> PolyhedronModel {
        return PolyhedronModel(
            vertices: [
                [1.0, 1.0, 1.0],
                [1.0, -1.0, -1.0],
                [-1.0, 1.0, -1.0],
                [-1.0, -1.0, 1.0]
            ],
            faces: [
                [0, 1, 2],
                [0, 2, 3],
                [0, 3, 1],
                [1, 3, 2]
            ],
            name: "T",
            faceClasses: []
        )
    }
}

