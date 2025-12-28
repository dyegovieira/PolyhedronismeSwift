//
// PolyhedronismeSwift
// TrisubOperator.swift
//
// Trisub operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct TrisubParameters: Sendable {
    public let n: Int
    
    public init(n: Int = 2) {
        self.n = n
    }
}

private struct VertexHash: Hashable {
    private let x: Int64
    private let y: Int64
    private let z: Int64
    
    init(vector: Vec3, precision: Double) {
        let scale = 1.0 / precision
        self.x = Int64((vector[0] * scale).rounded())
        self.y = Int64((vector[1] * scale).rounded())
        self.z = Int64((vector[2] * scale).rounded())
    }
}

internal struct TrisubOperator: ParameterizedPolyhedronOperator {
    public typealias Parameters = TrisubParameters
    
    public let identifier: String = "u"
    
    public init() {}
    
    public func apply(to polyhedron: PolyhedronModel, parameters: TrisubParameters) async throws -> PolyhedronModel {
        let n = parameters.n
        
        for fn in 0..<polyhedron.faces.count {
            if polyhedron.faces[fn].count != 3 {
                return polyhedron
            }
        }
        
        let faceCount = polyhedron.faces.count
        let vertexAssignments = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, [(String, Vec3)])] = []
            local.reserveCapacity(range.count)
            for fn in range {
                let face = polyhedron.faces[fn]
                guard face.count >= 3 else { continue }
                let i1 = face[face.count - 3]
                let i2 = face[face.count - 2]
                let i3 = face[face.count - 1]
                let v1 = polyhedron.vertices[i1]
                let v2 = polyhedron.vertices[i2]
                let v3 = polyhedron.vertices[i3]
                let v21 = Vector3.subtract(v2, v1)
                let v31 = Vector3.subtract(v3, v1)
                var entries: [(String, Vec3)] = []
                
                for i in 0...n {
                    for j in 0...(n - i) {
                        let v = Vector3.add(
                            Vector3.add(v1, Vector3.multiply(Double(i) / Double(n), v21)),
                            Vector3.multiply(Double(j) / Double(n), v31)
                        )
                        entries.append(("v\(fn)-\(i)-\(j)", v))
                    }
                }
                local.append((fn, entries))
            }
            return local
        }
        
        var faceVertexRecords = Array(repeating: [(String, Vec3)](), count: faceCount)
        for chunk in vertexAssignments {
            for entry in chunk {
                faceVertexRecords[entry.0] = entry.1
            }
        }
        
        var newVs: [Vec3] = []
        var vmap: [String: Int] = [:]
        for entries in faceVertexRecords {
            for entry in entries {
                vmap[entry.0] = newVs.count
                newVs.append(entry.1)
            }
        }
        
        let EPSILON_CLOSE = 1.0e-8
        var uniqVs: [Vec3] = []
        var uniqmap: [Int: Int] = [:]
        var vertexLookup: [VertexHash: Int] = [:]
        
        for (idx, vertex) in newVs.enumerated() {
            let hash = VertexHash(vector: vertex, precision: EPSILON_CLOSE)
            if let existing = vertexLookup[hash],
               Vector3.magnitude(Vector3.subtract(vertex, uniqVs[existing])) < EPSILON_CLOSE {
                uniqmap[idx] = existing
            } else {
                let newIndex = uniqVs.count
                uniqVs.append(vertex)
                vertexLookup[hash] = newIndex
                uniqmap[idx] = newIndex
            }
        }
        
        var faces: [Face] = []
        let vmapSnapshot = vmap
        let uniqmapSnapshot = uniqmap
        let pendingInstructions = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, [Face])] = []
            local.reserveCapacity(range.count)
            for fn in range {
                var localFaces: [Face] = []
                for i in 0..<n {
                    for j in 0...(n - i - 1) {
                        guard let idx1 = vmapSnapshot["v\(fn)-\(i)-\(j)"],
                              let idx2 = vmapSnapshot["v\(fn)-\(i+1)-\(j)"],
                              let idx3 = vmapSnapshot["v\(fn)-\(i)-\(j+1)"],
                              let u1 = uniqmapSnapshot[idx1],
                              let u2 = uniqmapSnapshot[idx2],
                              let u3 = uniqmapSnapshot[idx3] else {
                            continue
                        }
                        localFaces.append([u1, u2, u3])
                    }
                }
                for i in 1..<n {
                    for j in 0...(n - i - 1) {
                        guard let idx1 = vmapSnapshot["v\(fn)-\(i)-\(j)"],
                              let idx2 = vmapSnapshot["v\(fn)-\(i)-\(j+1)"],
                              let idx3 = vmapSnapshot["v\(fn)-\(i-1)-\(j+1)"],
                              let u1 = uniqmapSnapshot[idx1],
                              let u2 = uniqmapSnapshot[idx2],
                              let u3 = uniqmapSnapshot[idx3] else {
                            continue
                        }
                        localFaces.append([u1, u2, u3])
                    }
                }
                local.append((fn, localFaces))
            }
            return local
        }
        
        var faceInstructions = Array(repeating: [Face](), count: faceCount)
        for chunk in pendingInstructions {
            for entry in chunk {
                faceInstructions[entry.0] = entry.1
            }
        }
        
        for entry in faceInstructions {
            faces.append(contentsOf: entry)
        }
        
        return PolyhedronModel(
            vertices: uniqVs,
            faces: faces,
            name: "u\(n)\(polyhedron.name)",
            faceClasses: []
        )
    }
}

