//
// PolyhedronismeSwift
// ReflectOperator.swift
//
// Reflect operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct ReflectOperator: PolyhedronOperator {
    public let identifier: String = "r"
    
    public init() {}
    
    public func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        
        let reflectedVertices = polyhedron.vertices.map { vertex in
            Vector3.multiply(-1.0, vertex)
        }
        
        let reflectedFaces = polyhedron.faces.map { face in
            Array(face.reversed())
        }
        
        return PolyhedronModel(
            vertices: reflectedVertices,
            faces: reflectedFaces,
            name: "r\(polyhedron.name)",
            faceClasses: polyhedron.faceClasses
        )
    }
}

