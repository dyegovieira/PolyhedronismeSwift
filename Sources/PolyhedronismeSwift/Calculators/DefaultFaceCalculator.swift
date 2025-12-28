//
// PolyhedronismeSwift
// DefaultFaceCalculator.swift
//
// Face calculator for computing face geometry and topology
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultFaceCalculator: FaceCalculator {
    private let vertexCalculator: VertexCalculator
    
    public init(vertexCalculator: VertexCalculator = DefaultVertexCalculator()) {
        self.vertexCalculator = vertexCalculator
    }
    
    public func calculateCenters(from polyhedron: PolyhedronModel) async -> [Vec3] {
        let faceCount = polyhedron.faces.count
        guard faceCount > 0 else { return [] }
        
        let results = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, Vec3)] = []
            local.reserveCapacity(range.count)
            for idx in range {
                local.append((idx, self.center(for: idx, polyhedron: polyhedron)))
            }
            return local
        }
        
        var centers = Array(repeating: Vec3.zero(), count: faceCount)
        for chunk in results {
            for entry in chunk {
                centers[entry.0] = entry.1
            }
        }
        return centers
    }
    
    public func calculateNormals(from polyhedron: PolyhedronModel) async -> [Vec3] {
        let faceCount = polyhedron.faces.count
        guard faceCount > 0 else { return [] }
        
        let results = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, Vec3)] = []
            local.reserveCapacity(range.count)
            for idx in range {
                local.append((idx, self.normal(for: idx, polyhedron: polyhedron)))
            }
            return local
        }
        
        var normals = Array(repeating: Vec3.zero(), count: faceCount)
        for chunk in results {
            for entry in chunk {
                normals[entry.0] = entry.1
            }
        }
        return normals
    }
    
    private func center(for index: Int, polyhedron: PolyhedronModel) -> Vec3 {
        let face = polyhedron.faces[index]
        guard face.count >= 3 else { return Vec3.zero() }
        let faceVertices = face.compactMap { idx -> Vec3? in
            guard idx >= 0 && idx < polyhedron.vertices.count else { return nil }
            return polyhedron.vertices[idx]
        }
        guard !faceVertices.isEmpty else { return Vec3.zero() }
        return vertexCalculator.calculateCentroid(of: faceVertices)
    }
    
    private func normal(for index: Int, polyhedron: PolyhedronModel) -> Vec3 {
        let face = polyhedron.faces[index]
        guard face.count >= 3 else { return Vec3.zero() }
        let faceVertices = face.compactMap { idx -> Vec3? in
            guard idx >= 0 && idx < polyhedron.vertices.count else { return nil }
            return polyhedron.vertices[idx]
        }
        return GeometryUtils.calculateNormal(faceVertices)
    }
}

