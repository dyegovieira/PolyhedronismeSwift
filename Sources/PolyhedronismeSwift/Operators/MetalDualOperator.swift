//
// PolyhedronismeSwift
// MetalDualOperator.swift
//
// Metal-accelerated Dual operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalDualOperator: PolyhedronOperator {
    public let identifier: String = "d"
    
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
        // 1. Compute Face Centroids (New Vertices) on GPU
        let vertices = polyhedron.vertices.map { SIMD3<Float>(Float($0.x), Float($0.y), Float($0.z)) }
        
        // Flatten faces for GPU
        var flatIndices: [UInt32] = []
        var faceInfos: [FaceInfo] = []
        for face in polyhedron.faces {
            faceInfos.append(FaceInfo(start: UInt32(flatIndices.count), count: UInt32(face.count)))
            flatIndices.append(contentsOf: face.map { UInt32($0) })
        }
        
        guard let vertexBuffer = bufferProvider.makeBuffer(from: vertices),
              let faceInfoBuffer = bufferProvider.makeBuffer(from: faceInfos),
              let indexBuffer = bufferProvider.makeBuffer(from: flatIndices),
              let centroidBuffer = bufferProvider.makeBuffer(length: polyhedron.faces.count * MemoryLayout<SIMD3<Float>>.stride) else {
            throw MetalError.deviceNotFound
        }
        
        let pipeline = try await pipelineFactory.pipeline(for: "face_centroid_kernel")
        
        guard let commandQueue = metalConfig.commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalError.deviceNotFound
        }
        
        var faceCount = UInt32(polyhedron.faces.count)
        
        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(faceInfoBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(centroidBuffer, offset: 0, index: 3)
        computeEncoder.setBytes(&faceCount, length: MemoryLayout<UInt32>.stride, index: 4)
        
        let threadGroupSize = MetalSize(width: 64, height: 1, depth: 1)
        let threadGroups = MetalSize(width: (polyhedron.faces.count + 63) / 64, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        await commandBuffer.completed()
        
        // 2. Read back centroids
        let pCentroids = centroidBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: polyhedron.faces.count)
        var newVertices: [Vec3] = []
        newVertices.reserveCapacity(polyhedron.faces.count)
        for i in 0..<polyhedron.faces.count {
            let v = pCentroids[i]
            newVertices.append(Vec3(Double(v.x), Double(v.y), Double(v.z)))
        }
        
        // 3. Construct Faces on CPU
        // Build Directed Edge Map: (u, v) -> FaceIndex
        // Edge (u, v) means u -> v in the face loop
        var edgeToFace: [DirectedEdge: Int] = [:]
        for (faceIdx, face) in polyhedron.faces.enumerated() {
            var v1 = face[face.count - 1]
            for v2 in face {
                edgeToFace[DirectedEdge(from: v1, to: v2)] = faceIdx
                v1 = v2
            }
        }
        
        var newFaces: [[Int]] = []
        newFaces.reserveCapacity(polyhedron.vertices.count)
        
        // Build Vertex -> One Adjacent Face Index mapping
        // This allows us to find a starting face for each vertex
        var vertexStartFace: [Int: Int] = [:]
        
        for (faceIdx, face) in polyhedron.faces.enumerated() {
            var v1 = face[face.count - 1]
            for v2 in face {
                edgeToFace[DirectedEdge(from: v1, to: v2)] = faceIdx
                if vertexStartFace[v1] == nil {
                    vertexStartFace[v1] = faceIdx
                }
                v1 = v2
            }
        }
        
        for i in 0..<polyhedron.vertices.count {
            guard let startFaceIdx = vertexStartFace[i] else {
                // Vertex not used in any face? Skip or add empty?
                continue
            }
            
            var faceLoop: [Int] = []
            var currFaceIdx = startFaceIdx
            
            // Walk around vertex i
            // We are in currFaceIdx. It contains vertex i.
            // We need to find the edge in currFaceIdx that goes INTO i (u -> i).
            // Then the adjacent face across (i -> u) is the next face?
            // Wait.
            // Face 1: ... -> u -> i -> ...
            // Face 2: ... -> i -> u -> ... (shares edge u-i, but reversed)
            // So Face 2 is adjacent to Face 1 across edge u-i.
            // In Dual, the new face for vertex i connects Centroid(Face 1) -> Centroid(Face 2).
            // So we move from Face 1 to Face 2.
            // Face 1 has edge u->i.
            // Face 2 has edge i->u.
            // So we look for edge (i, u) in edgeToFace map.
            
            // Algorithm:
            // 1. Start at currFaceIdx.
            // 2. Find vertex 'u' such that (u -> i) is in currFaceIdx.
            //    (This is the vertex preceding i in currFaceIdx).
            // 3. Look up face for edge (i, u). This is nextFaceIdx.
            // 4. Add currFaceIdx to loop.
            // 5. currFaceIdx = nextFaceIdx.
            // 6. Repeat until currFaceIdx == startFaceIdx.
            
            // We need to find 'u' quickly.
            // We can store (FaceIdx, VertexIdx) -> PrecedingVertexIdx?
            // Or just search the face. Faces are small.
            
            var visitedFaces = Set<Int>()
            var infiniteLoopGuard = 0
            var isValidLoop = false
            
            repeat {
                faceLoop.append(currFaceIdx)
                visitedFaces.insert(currFaceIdx)
                
                let face = polyhedron.faces[currFaceIdx]
                guard let idxOfI = face.firstIndex(of: i) else { break }
                
                let idxOfU = (idxOfI - 1 + face.count) % face.count
                let u = face[idxOfU]
                
                guard let nextFace = edgeToFace[DirectedEdge(from: i, to: u)] else {
                    break
                }
                
                currFaceIdx = nextFace
                infiniteLoopGuard += 1
                
                if currFaceIdx == startFaceIdx {
                    isValidLoop = true
                }
            } while currFaceIdx != startFaceIdx && infiniteLoopGuard < 100
            
            if isValidLoop && !faceLoop.isEmpty {
                newFaces.append(faceLoop)
            }
        }
        
        var newName = polyhedron.name
        if let firstChar = newName.first, firstChar != "d" {
            newName = "d\(newName)"
        } else if newName.count > 1 {
            let start = newName.index(newName.startIndex, offsetBy: 1)
            newName = String(newName[start...])
        }
        
        return PolyhedronModel(
            vertices: newVertices,
            faces: newFaces,
            name: newName,
            faceClasses: []
        )
    }
}

struct DirectedEdge: Hashable {
    let from: Int
    let to: Int
}
