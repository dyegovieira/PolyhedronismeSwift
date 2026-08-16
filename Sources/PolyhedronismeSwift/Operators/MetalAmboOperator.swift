//
// PolyhedronismeSwift
// MetalAmboOperator.swift
//
// Metal-accelerated Ambo operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalAmboOperator: PolyhedronOperator {
    public let identifier: String = "a"

    private let executor: MetalExecutor

    init(executor: MetalExecutor) {
        self.executor = executor
    }
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        // 1. Extract Unique Edges and Build Map
        let (edges, edgeMap) = extractEdges(from: polyhedron)
        let edgeCount = edges.count
        
        guard edgeCount > 0 else { return polyhedron }
        
        let result = try await executor.ambo(
            MetalAmboRequest(vertices: polyhedron.vertices, edges: edges)
        )
        
        // 4. Construct Faces on CPU
        var newFaces: [[Int]] = []
        
        // 4a. Face Faces (Center faces)
        for face in polyhedron.faces {
            var newFace: [Int] = []
            var v1 = face[face.count - 1]
            for v2 in face {
                if let edgeIdx = edgeMap[EdgeKey(v1, v2)] {
                    newFace.append(edgeIdx)
                }
                v1 = v2
            }
            newFaces.append(newFace)
        }
        
        // 4b. Vertex Faces (Corner faces)
        // Collect segments for each vertex
        var vertexSegments = Array(repeating: [Int: Int](), count: polyhedron.vertices.count)
        
        for face in polyhedron.faces {
            var v1 = face[face.count - 1] // Previous
            var v2 = face[0] // Current
            
            for i in 0..<face.count {
                let v3 = face[(i + 1) % face.count] // Next
                
                // Edge v1-v2 and v2-v3 meet at v2
                // Ambo creates edge from mid(v2,v3) to mid(v1,v2) for the face at v2
                if let idx1 = edgeMap[EdgeKey(v2, v3)],
                   let idx2 = edgeMap[EdgeKey(v1, v2)] {
                    vertexSegments[v2][idx1] = idx2 // idx1 -> idx2
                }
                
                v1 = v2
                v2 = v3
            }
        }
        
        // Stitch segments
        for segments in vertexSegments {
            guard !segments.isEmpty else { continue }
            
            // Find loops
            var visited = Set<Int>()
            for startNode in segments.keys {
                if visited.contains(startNode) { continue }
                
                var loop: [Int] = []
                var curr = startNode
                while !visited.contains(curr) {
                    visited.insert(curr)
                    loop.append(curr)
                    if let next = segments[curr] {
                        curr = next
                    } else {
                        break // Broken loop
                    }
                }
                // Only add if it's a closed loop (returned to start)
                // Actually, if we hit a visited node that is NOT start, it's a merge?
                // But for manifold meshes, it should be simple loops.
                // If curr == startNode, it's a loop.
                // Wait, the loop logic above stops if visited.
                // We need to check if the last 'curr' connects back to 'startNode' or if we just stopped.
                // Actually, we should just follow until we hit start or dead end.
                
                // Better loop:
                // Pick a start. Follow.
                // If we hit start, valid face.
                // If we hit dead end, open face (ignore or add?)
                // Polyhedronisme usually produces closed faces.
                
                // Let's re-do loop extraction properly
            }
            
            // Optimized stitching:
            // Since we used a Dictionary [From -> To], we can just pick a key, follow it, remove from dict.
            var mutableSegments = segments
            while let (start, _) = mutableSegments.first {
                var loop: [Int] = []
                var curr = start
                while let next = mutableSegments[curr] {
                    mutableSegments.removeValue(forKey: curr)
                    loop.append(curr)
                    curr = next
                    if curr == start {
                        break
                    }
                }
                newFaces.append(loop)
            }
        }
        
        return PolyhedronModel(
            vertices: result.vertices,
            faces: newFaces,
            name: "a\(polyhedron.name)",
            faceClasses: []
        )
    }
    
    private func extractEdges(from polyhedron: PolyhedronModel) -> ([MetalAmboEdge], [EdgeKey: Int]) {
        var uniqueEdges: [EdgeKey: Int] = [:]
        var edgeList: [MetalAmboEdge] = []
        
        for face in polyhedron.faces {
            var v1 = face[face.count - 1]
            for v2 in face {
                let key = EdgeKey(v1, v2)
                if uniqueEdges[key] == nil {
                    uniqueEdges[key] = edgeList.count
                    edgeList.append(MetalAmboEdge(v1: UInt32(key.lower), v2: UInt32(key.upper)))
                }
                v1 = v2
            }
        }
        return (edgeList, uniqueEdges)
    }
}

struct AmboParams {
    var edgeCount: UInt32
    var vertexCount: UInt32
}

struct MetalAmboEdge: Sendable {
    var v1: UInt32
    var v2: UInt32
}
