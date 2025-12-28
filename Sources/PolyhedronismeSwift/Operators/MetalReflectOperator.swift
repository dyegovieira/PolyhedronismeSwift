//
// PolyhedronismeSwift
// MetalReflectOperator.swift
//
// Metal-accelerated Reflect operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalReflectOperator: PolyhedronOperator {
    public let identifier: String = "r"
    
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
        // Handle empty case
        guard !polyhedron.vertices.isEmpty else {
            return PolyhedronModel(
                vertices: [],
                faces: polyhedron.faces.map { Array($0.reversed()) },
                name: "r\(polyhedron.name)",
                faceClasses: polyhedron.faceClasses
            )
        }
        
        // 1. Compute Reflected Vertices on GPU
        let vertices = polyhedron.vertices.map { SIMD3<Float>(Float($0.x), Float($0.y), Float($0.z)) }
        
        guard let vertexBuffer = bufferProvider.makeBuffer(from: vertices),
              let newVertexBuffer = bufferProvider.makeBuffer(length: vertices.count * MemoryLayout<SIMD3<Float>>.stride) else {
            throw MetalError.deviceNotFound
        }
        
        let pipeline = try await pipelineFactory.pipeline(for: "reflect_vertex_kernel")
        
        guard let commandQueue = metalConfig.commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalError.deviceNotFound
        }
        
        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(newVertexBuffer, offset: 0, index: 1)
        
        let threadGroupSize = MetalSize(width: 64, height: 1, depth: 1)
        let threadGroups = MetalSize(width: (vertices.count + 63) / 64, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        await commandBuffer.completed()
        
        // 2. Read back vertices
        let pVertices = newVertexBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: vertices.count)
        var resultVertices: [Vec3] = []
        resultVertices.reserveCapacity(vertices.count)
        for i in 0..<vertices.count {
            let v = pVertices[i]
            resultVertices.append(Vec3(Double(v.x), Double(v.y), Double(v.z)))
        }
        
        // 3. Reverse Faces on CPU
        let resultFaces = polyhedron.faces.map { Array($0.reversed()) }
        
        return PolyhedronModel(
            vertices: resultVertices,
            faces: resultFaces,
            name: "r\(polyhedron.name)",
            faceClasses: polyhedron.faceClasses
        )
    }
}
