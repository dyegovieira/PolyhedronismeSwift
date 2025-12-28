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
    
    private let metalConfig: MetalConfiguration
    private let pipelineFactory: ComputePipelineFactory
    private let bufferProvider: MetalBufferProvider
    
    init?(metalConfig: MetalConfiguration, pipelineFactory: ComputePipelineFactory) {
        guard let device = metalConfig.device,
              let bufferProvider = MetalBufferProvider(device: device) else {
            return nil
        }
        self.metalConfig = metalConfig
        self.pipelineFactory = pipelineFactory
        self.bufferProvider = bufferProvider
    }
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        // 1. Extract Unique Edges and Build Map
        let (edges, edgeMap) = extractEdges(from: polyhedron)
        let edgeCount = edges.count
        
        guard edgeCount > 0 else { return polyhedron }
        
        // 2. Compute New Vertices (Midpoints) on GPU
        let vertices = polyhedron.vertices.map { SIMD3<Float>(Float($0.x), Float($0.y), Float($0.z)) }
        
        guard let vertexBuffer = bufferProvider.makeBuffer(from: vertices),
              let edgeBuffer = bufferProvider.makeBuffer(from: edges),
              let newVertexBuffer = bufferProvider.makeBuffer(length: edgeCount * MemoryLayout<SIMD3<Float>>.stride) else {
            throw MetalError.deviceNotFound
        }
        
        let pipeline = try await pipelineFactory.pipeline(for: "ambo_vertex_kernel")
        
        guard let commandQueue = metalConfig.commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalError.deviceNotFound
        }
        
        var params = AmboParams(edgeCount: UInt32(edgeCount), vertexCount: UInt32(vertices.count))
        
        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setBytes(&params, length: MemoryLayout<AmboParams>.stride, index: 0)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(edgeBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(newVertexBuffer, offset: 0, index: 3)
        
        let threadGroupSize = MetalSize(width: 64, height: 1, depth: 1)
        let threadGroups = MetalSize(width: (edgeCount + 63) / 64, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        await commandBuffer.completed()
        
        // 3. Read back vertices
        let pVertices = newVertexBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: edgeCount)
        var resultVertices: [Vec3] = []
        resultVertices.reserveCapacity(edgeCount)
        for i in 0..<edgeCount {
            let v = pVertices[i]
            resultVertices.append(Vec3(Double(v.x), Double(v.y), Double(v.z)))
        }
        
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
            vertices: resultVertices,
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

struct MetalAmboEdge {
    var v1: UInt32
    var v2: UInt32
}
