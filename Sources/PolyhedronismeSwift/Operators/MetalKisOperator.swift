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
    
    func apply(to polyhedron: PolyhedronModel, parameters: KisParameters) async throws -> PolyhedronModel {
        let n = parameters.n
        let apexDistance = Float(parameters.apexDistance)
        
        // 1. Setup Buffers
        let vertices = polyhedron.vertices.map { SIMD3<Float>(Float($0.x), Float($0.y), Float($0.z)) }
        guard let vertexBuffer = bufferProvider.makeBuffer(from: vertices) else {
            throw MetalError.deviceNotFound
        }
        
        // Flatten faces
        var flatIndices: [UInt32] = []
        var faceInfos: [FaceInfo] = []
        for face in polyhedron.faces {
            faceInfos.append(FaceInfo(start: UInt32(flatIndices.count), count: UInt32(face.count)))
            flatIndices.append(contentsOf: face.map { UInt32($0) })
        }
        
        guard let faceInfoBuffer = bufferProvider.makeBuffer(from: faceInfos),
              let indexBuffer = bufferProvider.makeBuffer(from: flatIndices) else {
            throw MetalError.deviceNotFound
        }
        
        // Output buffers
        let newVertexCount = vertices.count + polyhedron.faces.count
        guard let newVertexBuffer = bufferProvider.makeBuffer(length: newVertexCount * MemoryLayout<SIMD3<Float>>.stride) else {
            throw MetalError.deviceNotFound
        }
        
        // Copy original vertices
        let pVertices = newVertexBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: newVertexCount)
        for (i, v) in vertices.enumerated() {
            pVertices[i] = v
        }
        
        // 2. Compute Apexes
        let vertexPipeline = try await pipelineFactory.pipeline(for: "kis_vertex_kernel")
        
        guard let commandQueue = metalConfig.commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalError.deviceNotFound
        }
        
        var params = KisParams(
            n: Int32(n),
            apexDistance: apexDistance,
            faceCount: UInt32(polyhedron.faces.count),
            vertexCount: UInt32(vertices.count)
        )
        
        computeEncoder.setComputePipelineState(vertexPipeline)
        computeEncoder.setBytes(&params, length: MemoryLayout<KisParams>.stride, index: 0)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(faceInfoBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(newVertexBuffer, offset: 0, index: 4)
        
        let threadGroupSize = MetalSize(width: 32, height: 1, depth: 1)
        let threadGroups = MetalSize(width: (polyhedron.faces.count + 31) / 32, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        await commandBuffer.completed()
        
        // 3. Reconstruct Topology (CPU for now)
        var resultVertices: [Vec3] = []
        resultVertices.reserveCapacity(newVertexCount)
        for i in 0..<newVertexCount {
            let v = pVertices[i]
            resultVertices.append(Vec3(Double(v.x), Double(v.y), Double(v.z)))
        }
        
        var finalFaces: [[Int]] = []
        let apexBaseIndex = vertices.count
        
        // We need to filter out unused apexes to keep the model clean
        // Or we can just leave them if we don't care about unused vertices (Polyhedronisme usually cleans up?)
        // Let's do a clean reconstruction.
        
        var finalVertices: [Vec3] = []
        var vertexMap: [Int: Int] = [:] // Old index -> New index
        
        // Add original vertices
        finalVertices.append(contentsOf: resultVertices[0..<vertices.count])
        for i in 0..<vertices.count {
            vertexMap[i] = i
        }
        
        for (i, face) in polyhedron.faces.enumerated() {
            if n == 0 || face.count == n {
                let apexIndex = finalVertices.count
                finalVertices.append(resultVertices[apexBaseIndex + i])
                
                var v1 = face[face.count - 1]
                for v2 in face {
                    finalFaces.append([v1, v2, apexIndex])
                    v1 = v2
                }
            } else {
                finalFaces.append(face)
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

struct FaceInfo {
    var start: UInt32
    var count: UInt32
}
