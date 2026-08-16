//
// PolyhedronismeSwift
// MetalReflectOperator.swift
//
// Metal-accelerated Reflect operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalReflectOperator: PolyhedronOperator {
    public let identifier: String = "r"

    private let executor: MetalExecutor

    init(executor: MetalExecutor) {
        self.executor = executor
    }
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        // Handle empty case
        guard !polyhedron.vertices.isEmpty else {
            return PolyhedronModel(
                vertices: [],
                faces: polyhedron.faces.map { Array($0.reversed()) },
                name: "r\(polyhedron.name)",
                faceClasses: polyhedron.faceClasses
            )
        }
        
        let result = try await executor.reflect(MetalReflectRequest(vertices: polyhedron.vertices))
        
        // 3. Reverse Faces on CPU
        let resultFaces = polyhedron.faces.map { Array($0.reversed()) }
        
        return PolyhedronModel(
            vertices: result.vertices,
            faces: resultFaces,
            name: "r\(polyhedron.name)",
            faceClasses: polyhedron.faceClasses
        )
    }
}
