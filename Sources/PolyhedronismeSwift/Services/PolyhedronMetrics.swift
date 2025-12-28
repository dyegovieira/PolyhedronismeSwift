//
// PolyhedronismeSwift
// PolyhedronMetrics.swift
//
// Polyhedron metrics service for geometric calculations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultPolyhedronMetrics: PolyhedronMetricsCalculator {
    internal init() {}
    
    internal func calculateDataDescription(from model: PolyhedronModel) -> String {
        let nEdges = model.faces.count + model.vertices.count - 2
        return "\(model.faces.count) faces, \(nEdges) edges, \(model.vertices.count) vertices"
    }
    
    internal func calculateDetailedDescription(
        from model: PolyhedronModel,
        edgeCalculator: EdgeCalculator,
        faceCalculator: FaceCalculator
    ) async -> String {
        let minEdge = await calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        let minRadius = await calculateMinFaceRadius(from: model, edgeCalculator: edgeCalculator, faceCalculator: faceCalculator)
        return "min edge length \(minEdge)\n" +
               "min face radius \(minRadius)"
    }
    
    internal func calculateMinEdgeLength(from model: PolyhedronModel, edgeCalculator: EdgeCalculator) async -> Double {
        var cacheableModel = model
        let edges = await cacheableModel.cachedEdges(using: edgeCalculator)
        var min2 = Double.greatestFiniteMagnitude
        for e in edges {
            guard e.count == 2,
                  e[0] < cacheableModel.vertices.count,
                  e[1] < cacheableModel.vertices.count else {
                continue
            }
            let d2 = Vector3.magnitudeSquared(
                Vector3.subtract(cacheableModel.vertices[e[0]], cacheableModel.vertices[e[1]])
            )
            if d2 < min2 {
                min2 = d2
            }
        }
        return sqrt(min2)
    }
    
    internal func calculateMinFaceRadius(
        from model: PolyhedronModel,
        edgeCalculator: EdgeCalculator,
        faceCalculator: FaceCalculator
    ) async -> Double {
        var min2 = Double.greatestFiniteMagnitude
        var cacheableModel = model
        let centers = await cacheableModel.cachedCenters(using: faceCalculator)
        
        for (faceIndex, face) in cacheableModel.faces.enumerated() {
            guard faceIndex < centers.count else { continue }
            let c = centers[faceIndex]
            
            let faceEdges = edgeCalculator.faceToEdges(face)
            for e in faceEdges {
                guard e.count == 2,
                      e[0] < cacheableModel.vertices.count,
                      e[1] < cacheableModel.vertices.count else {
                    continue
                }
                let de2 = GeometryUtils.linePointDistanceSquared(
                    cacheableModel.vertices[e[0]],
                    cacheableModel.vertices[e[1]],
                    c
                )
                if de2 < min2 {
                    min2 = de2
                }
            }
        }
        return sqrt(min2)
    }
}

