//
// PolyhedronismeSwift
// CanonicalizationPipelineActor.swift
//
// Canonicalization pipeline actor service for parallel polyhedral processing
//
// Created by Dyego Vieira de Paula on 2025-11-17
// Built with AI-assisted development via Cursor IDE
//
import Dispatch
import Foundation
import os
import simd

// Use os.Logger to avoid conflict with our custom Logger protocol
typealias OSLogger = os.Logger

private typealias GPUVec3 = SIMD3<Float>

enum CanonicalizationStage: Sendable {
    case reciprocalC
    case reciprocalN
}

struct CanonicalizationTelemetry: Sendable {
    let stage: CanonicalizationStage
    let duration: TimeInterval
    let usedGPU: Bool
}

struct CanonicalizationStageResult: Sendable {
    let values: ContiguousArray<Vec3>
    let telemetry: CanonicalizationTelemetry
    
    func asArray() -> [Vec3] {
        Array(values)
    }
}

actor CanonicalizationPipelineActor {
    private let enableMetal: Bool
    private let logger = OSLogger(subsystem: "PolyhedronismeSwift", category: "CanonicalizationPipeline")
    private let metalReady: Bool
    
    private let device: MetalDevice?
    private let commandQueue: MetalCommandQueue?
    private let reciprocalCPipeline: MetalComputePipelineState?
    private let reciprocalNPipeline: MetalComputePipelineState?
    
    init(enableMetal: Bool = true) {
        self.enableMetal = enableMetal
        if enableMetal,
           let device = MetalWrapper.createSystemDefaultDevice(),
           let queue = device.makeCommandQueue(),
           let library = CanonicalizationPipelineActor.makeLibrary(for: device) {
            self.device = device
            self.commandQueue = queue
            self.reciprocalCPipeline = CanonicalizationPipelineActor.makePipelineState(
                name: "reciprocal_c_kernel",
                device: device,
                library: library
            )
            self.reciprocalNPipeline = CanonicalizationPipelineActor.makePipelineState(
                name: "reciprocal_n_kernel",
                device: device,
                library: library
            )
            self.metalReady = reciprocalCPipeline != nil && reciprocalNPipeline != nil
        } else {
            self.device = nil
            self.commandQueue = nil
            self.reciprocalCPipeline = nil
            self.reciprocalNPipeline = nil
            self.metalReady = false
        }
    }
    
    // Test-friendly initializer for dependency injection
    internal init(device: MetalDevice?, enableMetal: Bool = true) {
        self.enableMetal = enableMetal
        if enableMetal,
           let device = device,
           let queue = device.makeCommandQueue(),
           let library = CanonicalizationPipelineActor.makeLibrary(for: device) {
            self.device = device
            self.commandQueue = queue
            self.reciprocalCPipeline = CanonicalizationPipelineActor.makePipelineState(
                name: "reciprocal_c_kernel",
                device: device,
                library: library
            )
            self.reciprocalNPipeline = CanonicalizationPipelineActor.makePipelineState(
                name: "reciprocal_n_kernel",
                device: device,
                library: library
            )
            self.metalReady = reciprocalCPipeline != nil && reciprocalNPipeline != nil
        } else {
            self.device = nil
            self.commandQueue = nil
            self.reciprocalCPipeline = nil
            self.reciprocalNPipeline = nil
            self.metalReady = false
        }
    }
    
    func reciprocalC(vertices: ContiguousArray<Vec3>) async -> CanonicalizationStageResult {
        let start = ContinuousClock.now
        if enableMetal,
           metalReady,
           !vertices.isEmpty,
           let device,
           let commandQueue,
           let pipeline = reciprocalCPipeline {
            if let gpuResult = await gpuReciprocalC(
                vertices: vertices,
                device: device,
                queue: commandQueue,
                pipeline: pipeline
            ) {
                let duration = start.elapsedTime()
                logger.debug("reciprocalC GPU completed in \(duration, privacy: .public)s")
                return CanonicalizationStageResult(
                    values: gpuResult,
                    telemetry: CanonicalizationTelemetry(stage: .reciprocalC, duration: duration, usedGPU: true)
                )
            }
        }
        let fallback = CanonicalizationMath.reciprocalC(vertices: vertices)
        let duration = start.elapsedTime()
        logger.debug("reciprocalC CPU fallback completed in \(duration, privacy: .public)s")
        return CanonicalizationStageResult(
            values: fallback,
            telemetry: CanonicalizationTelemetry(stage: .reciprocalC, duration: duration, usedGPU: false)
        )
    }
    
    func reciprocalN(vertices: ContiguousArray<Vec3>, faces: [Face]) async -> CanonicalizationStageResult {
        let start = ContinuousClock.now
        if enableMetal,
           metalReady,
           !vertices.isEmpty,
           !faces.isEmpty,
           let device,
           let commandQueue,
           let pipeline = reciprocalNPipeline {
            if let gpuResult = await gpuReciprocalN(
                vertices: vertices,
                faces: faces,
                device: device,
                queue: commandQueue,
                pipeline: pipeline
            ) {
                let duration = start.elapsedTime()
                logger.debug("reciprocalN GPU completed in \(duration, privacy: .public)s")
                return CanonicalizationStageResult(
                    values: gpuResult,
                    telemetry: CanonicalizationTelemetry(stage: .reciprocalN, duration: duration, usedGPU: true)
                )
            }
        }
        let fallback = CanonicalizationMath.reciprocalN(vertices: vertices, faces: faces)
        let duration = start.elapsedTime()
        logger.debug("reciprocalN CPU fallback completed in \(duration, privacy: .public)s")
        return CanonicalizationStageResult(
            values: fallback,
            telemetry: CanonicalizationTelemetry(stage: .reciprocalN, duration: duration, usedGPU: false)
        )
    }
    
    private func gpuReciprocalC(
        vertices: ContiguousArray<Vec3>,
        device: MetalDevice,
        queue: MetalCommandQueue,
        pipeline: MetalComputePipelineState
    ) async -> ContiguousArray<Vec3>? {
        let count = vertices.count
        guard count > 0,
              let inBuffer = makeVertexBuffer(from: vertices, device: device),
              let outBuffer = device.makeBuffer(length: count * MemoryLayout<GPUVec3>.stride, options: .storageModeShared) else {
            return nil
        }
        
        var params = CanonicalizationScalarParams(count: UInt32(count))
        guard let paramsBuffer = device.makeBuffer(bytes: &params, length: MemoryLayout<CanonicalizationScalarParams>.stride, options: .storageModeShared),
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }
        
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(inBuffer, offset: 0, index: 0)
        encoder.setBuffer(outBuffer, offset: 0, index: 1)
        encoder.setBuffer(paramsBuffer, offset: 0, index: 2)
        let threads = MetalSize(width: min(pipeline.maxTotalThreadsPerThreadgroup, 64), height: 1, depth: 1)
        let groups = MetalSize(
            width: (count + threads.width - 1) / threads.width,
            height: 1,
            depth: 1
        )
        encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        encoder.endEncoding()
        commandBuffer.commit()
        await commandBuffer.completed()
        
        return readVertexBuffer(outBuffer, count: count)
    }
    
    private func gpuReciprocalN(
        vertices: ContiguousArray<Vec3>,
        faces: [Face],
        device: MetalDevice,
        queue: MetalCommandQueue,
        pipeline: MetalComputePipelineState
    ) async -> ContiguousArray<Vec3>? {
        let faceCount = faces.count
        guard faceCount > 0,
              let vertexBuffer = makeVertexBuffer(from: vertices, device: device) else {
            return nil
        }
        
        let flattened = flattenFaces(faces)
        guard let rangeBuffer = makeBuffer(from: flattened.ranges, device: device),
              let indexBuffer = makeBuffer(from: flattened.indices, device: device),
              let outBuffer = device.makeBuffer(length: faceCount * MemoryLayout<GPUVec3>.stride, options: .storageModeShared) else {
            return nil
        }
        
        var params = CanonicalizationFaceScalarParams(
            faceCount: UInt32(faceCount),
            vertexCount: UInt32(vertices.count)
        )
        guard let paramsBuffer = device.makeBuffer(
            bytes: &params,
            length: MemoryLayout<CanonicalizationFaceScalarParams>.stride,
            options: .storageModeShared
        ),
        let commandBuffer = queue.makeCommandBuffer(),
        let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }
        
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setBuffer(rangeBuffer, offset: 0, index: 1)
        encoder.setBuffer(indexBuffer, offset: 0, index: 2)
        encoder.setBuffer(outBuffer, offset: 0, index: 3)
        encoder.setBuffer(paramsBuffer, offset: 0, index: 4)
        let threads = MetalSize(width: min(pipeline.maxTotalThreadsPerThreadgroup, 64), height: 1, depth: 1)
        let groups = MetalSize(
            width: (faceCount + threads.width - 1) / threads.width,
            height: 1,
            depth: 1
        )
        encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        encoder.endEncoding()
        commandBuffer.commit()
        await commandBuffer.completed()
        
        return readVertexBuffer(outBuffer, count: faceCount)
    }
    
    private func makeVertexBuffer(
        from vectors: ContiguousArray<Vec3>,
        device: MetalDevice
    ) -> MetalBuffer? {
        var floatVectors = ContiguousArray<GPUVec3>()
        floatVectors.reserveCapacity(vectors.count)
        for vector in vectors {
            floatVectors.append(GPUVec3(
                Float(vector.x),
                Float(vector.y),
                Float(vector.z)
            ))
        }
        return floatVectors.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: buffer.count, options: .storageModeShared)
        }
    }
    
    private func makeBuffer<T>(
        from data: ContiguousArray<T>,
        device: MetalDevice
    ) -> MetalBuffer? {
        data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: buffer.count, options: .storageModeShared)
        }
    }
    
    private func readVertexBuffer(_ buffer: MetalBuffer, count: Int) -> ContiguousArray<Vec3>? {
        let pointer = buffer.contents().bindMemory(to: GPUVec3.self, capacity: count)
        var result = ContiguousArray<Vec3>()
        result.reserveCapacity(count)
        for index in 0..<count {
            let gpuVec = pointer[index]
            result.append(Vec3(
                Double(gpuVec.x),
                Double(gpuVec.y),
                Double(gpuVec.z)
            ))
        }
        return result
    }
    
    private func flattenFaces(_ faces: [Face]) -> (ranges: ContiguousArray<CanonicalizationFaceRange>, indices: ContiguousArray<UInt32>) {
        var ranges = ContiguousArray<CanonicalizationFaceRange>()
        var indices = ContiguousArray<UInt32>()
        ranges.reserveCapacity(faces.count)
        
        for face in faces {
            let start = UInt32(indices.count)
            for index in face {
                indices.append(UInt32(max(0, index)))
            }
            ranges.append(CanonicalizationFaceRange(start: start, count: UInt32(face.count)))
        }
        
        return (ranges: ranges, indices: indices)
    }
    
    private static func makePipelineState(
        name: String,
        device: MetalDevice,
        library: MetalLibrary
    ) -> MetalComputePipelineState? {
        guard let function = library.makeFunction(name: name) else {
            return nil
        }
        return try? device.makeComputePipelineState(function: function)
    }
    
    private static func makeLibrary(for device: MetalDevice) -> MetalLibrary? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(
            forResource: "CanonicalizationKernels",
            withExtension: "metal",
            subdirectory: "Metal"
        ),
           let source = try? String(contentsOf: url) {
            return try? device.makeLibrary(source: source, options: nil)
        }
        #endif
        return device.makeDefaultLibrary()
    }
}

private extension ContinuousClock.Instant {
    func elapsedTime() -> TimeInterval {
        let duration = self.duration(to: ContinuousClock.now)
        let seconds = Double(duration.components.seconds)
        let attoseconds = Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
        return seconds + attoseconds
    }
}

private struct CanonicalizationScalarParams {
    var count: UInt32
}

private struct CanonicalizationFaceRange {
    var start: UInt32
    var count: UInt32
}

private struct CanonicalizationFaceScalarParams {
    var faceCount: UInt32
    var vertexCount: UInt32
}

