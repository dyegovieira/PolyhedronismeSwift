//
// PolyhedronismeSwift
// DefaultEdgeCalculator.swift
//
// Edge calculator for computing edge connectivity and geometry
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultEdgeCalculator: EdgeCalculator {
    public init() {}
    
    public func faceToEdges(_ face: Face) -> [[Int]] {
        guard face.count >= 2 else { return [] }
        var edges: [[Int]] = []
        var v1 = face[face.count - 1]
        for v2 in face {
            edges.append([v1, v2])
            v1 = v2
        }
        return edges
    }
    
    public func calculateEdges(from polyhedron: PolyhedronModel) async -> [[Int]] {
        var uniqueEdges: [EdgeKey: [Int]] = [:]
        let faceCount = polyhedron.faces.count
        guard faceCount > 0 else { return [] }
        
        let results = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, [[Int]])] = []
            local.reserveCapacity(range.count)
            for idx in range {
                local.append((idx, self.faceToEdges(polyhedron.faces[idx])))
            }
            return local
        }
        
        var faceEdges = Array(repeating: [[Int]](), count: faceCount)
        for chunk in results {
            for entry in chunk {
                faceEdges[entry.0] = entry.1
            }
        }
        
        for edgeSet in faceEdges {
            for e in edgeSet {
                let a = e[0]
                let b = e[1]
                let key = EdgeKey(a, b)
                uniqueEdges[key] = e
            }
        }
        return Array(uniqueEdges.values)
    }
}

