//
// PolyhedronismeSwift
// Polyhedron.swift
//
// Polyhedron domain model for representing polyhedral shapes
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public struct Polyhedron: Sendable {
    public var vertices: [Vec3]
    public var faces: [Face]
    public var name: String
    public var faceClasses: [Int]
    public var recipe: String?
    
    public init(
        vertices: [Vec3] = [],
        faces: [Face] = [],
        name: String = "null polyhedron",
        faceClasses: [Int] = [],
        recipe: String? = nil
    ) {
        self.vertices = vertices
        self.faces = faces
        self.name = name
        self.faceClasses = faceClasses
        self.recipe = recipe
    }
}

extension Polyhedron {
    init(_ model: PolyhedronModel, recipe: String? = nil) {
        self.init(
            vertices: model.vertices,
            faces: model.faces,
            name: model.name,
            faceClasses: model.faceClasses,
            recipe: recipe
        )
    }
}
