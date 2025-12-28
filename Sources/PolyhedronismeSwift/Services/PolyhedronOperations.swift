//
// PolyhedronismeSwift
// PolyhedronOperations.swift
//
// Polyhedron operations service for geometric transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultPolyhedronOperations: PolyhedronOperationsProtocol {
    internal init() {}
    
    internal func recenter(_ model: PolyhedronModel, edgeCalculator: EdgeCalculator) async -> PolyhedronModel {
        var cacheableModel = model
        let edges = await cacheableModel.cachedEdges(using: edgeCalculator)
        let edgecenters = edges.map { edge in
            guard edge.count == 2,
                  edge[0] < cacheableModel.vertices.count,
                  edge[1] < cacheableModel.vertices.count else {
                return Vec3.zero()
            }
            return GeometryUtils.tangentPoint(
                cacheableModel.vertices[edge[0]],
                cacheableModel.vertices[edge[1]]
            )
        }
        
        var polycenter: Vec3 = [0, 0, 0]
        for v in edgecenters {
            polycenter = Vector3.add(polycenter, v)
        }
        
        guard !edges.isEmpty else {
            return model
        }
        
        polycenter = Vector3.multiply(1.0 / Double(edges.count), polycenter)
        
        let recenteredVertices = cacheableModel.vertices.map { vertex in
            Vector3.subtract(vertex, polycenter)
        }
        
        return PolyhedronModel(
            vertices: recenteredVertices,
            faces: model.faces,
            name: model.name,
            faceClasses: model.faceClasses
        )
    }
    
    internal func rescale(_ model: PolyhedronModel) -> PolyhedronModel {
        let maxExtent = model.vertices.map { Vector3.magnitude($0) }.max() ?? 1.0
        guard maxExtent > 0 else {
            return model
        }
        
        let scale = 1.0 / maxExtent
        let rescaledVertices = model.vertices.map { vertex in
            Vector3.multiply(scale, vertex)
        }
        
        return PolyhedronModel(
            vertices: rescaledVertices,
            faces: model.faces,
            name: model.name,
            faceClasses: model.faceClasses
        )
    }
}

