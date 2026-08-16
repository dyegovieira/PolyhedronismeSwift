//
// PolyhedronismeSwift
// MetalKisOperator.swift
//
// Metal-accelerated Kis operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalKisOperator: ParameterizedPolyhedronOperator {
    public typealias Parameters = KisParameters
    
    public let identifier: String = "k"
    
    private let executor: MetalExecutor

    init(executor: MetalExecutor) {
        self.executor = executor
    }
    
    func apply(to polyhedron: PolyhedronModel, parameters: KisParameters) async throws -> PolyhedronModel {
        let n = parameters.n
        // Flatten faces for the value-only Metal request.
        var flatIndices: [UInt32] = []
        var faceInfos: [FaceInfo] = []
        for face in polyhedron.faces {
            faceInfos.append(FaceInfo(start: UInt32(flatIndices.count), count: UInt32(face.count)))
            flatIndices.append(contentsOf: face.map { UInt32($0) })
        }
        
        let result = try await executor.kis(
            MetalKisRequest(
                vertices: polyhedron.vertices,
                faceInfos: faceInfos,
                faceIndices: flatIndices,
                parameters: parameters
            )
        )
        
        let apexBaseIndex = polyhedron.vertices.count
        
        // Pre-calculation: identify which faces need kis and build apex index mapping
        var kisFaceCount = 0
        var faceIndexToApexIndex: [Int: Int] = [:]
        var facesNeedKis: [Bool] = []
        facesNeedKis.reserveCapacity(polyhedron.faces.count)
        
        for (i, face) in polyhedron.faces.enumerated() {
            let needsKis = n == 0 || face.count == n
            facesNeedKis.append(needsKis)
            if needsKis {
                faceIndexToApexIndex[i] = polyhedron.vertices.count + kisFaceCount
                kisFaceCount += 1
            }
        }
        
        // Pre-allocate arrays with known sizes
        var finalVertices: [Vec3] = []
        finalVertices.reserveCapacity(polyhedron.vertices.count + kisFaceCount)
        
        // Add original vertices
        finalVertices.append(contentsOf: result.vertices[0..<polyhedron.vertices.count])
        
        // Add apex vertices (in order)
        for (i, needsKis) in facesNeedKis.enumerated() {
            if needsKis {
                finalVertices.append(result.vertices[apexBaseIndex + i])
            }
        }
        
        // Parallel processing: build faces in parallel
        let faceCount = polyhedron.faces.count
        let faceIndexToApexIndexSnapshot = faceIndexToApexIndex
        let facesNeedKisSnapshot = facesNeedKis
        
        let faceResults = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, [[Int]])] = []
            local.reserveCapacity(range.count)
            
            for idx in range {
                let face = polyhedron.faces[idx]
                var newFaces: [[Int]] = []
                
                if facesNeedKisSnapshot[idx] {
                    if let apexIndex = faceIndexToApexIndexSnapshot[idx] {
                        var v1 = face[face.count - 1]
                        for v2 in face {
                            newFaces.append([v1, v2, apexIndex])
                            v1 = v2
                        }
                    }
                } else {
                    newFaces.append(face)
                }
                
                local.append((idx, newFaces))
            }
            
            return local
        }
        
        // Assemble results in order (ParallelExecutor already returns chunks in order)
        var finalFaces: [[Int]] = []
        finalFaces.reserveCapacity(faceCount * 3) // Rough estimate: most kis faces become multiple triangles
        
        for chunk in faceResults {
            for (_, faces) in chunk {
                finalFaces.append(contentsOf: faces)
            }
        }
        
        return PolyhedronModel(
            vertices: finalVertices,
            faces: finalFaces,
            name: "k\(n == 0 ? "" : "\(n)")\(polyhedron.name)",
            faceClasses: []
        )
    }
}

struct KisParams {
    var n: Int32
    var apexDistance: Float
    var faceCount: UInt32
    var vertexCount: UInt32
}

struct FaceInfo: Sendable {
    var start: UInt32
    var count: UInt32
}
