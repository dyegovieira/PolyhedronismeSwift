//
// PolyhedronismeSwift
// MetalExecutor.swift
//
// Actor-isolated Metal execution boundary. Metal framework objects never cross
// this boundary; callers exchange only Sendable geometry values.
//

import Foundation
#if canImport(Metal)
@preconcurrency import Metal
#endif

internal struct MetalCapabilities: Sendable, Equatable {
    let isAvailable: Bool
    static let unavailable = MetalCapabilities(isAvailable: false)
}

internal struct MetalReflectRequest: Sendable { let vertices: [Vec3] }
internal struct MetalReflectResult: Sendable { let vertices: [Vec3] }
internal struct MetalAmboRequest: Sendable { let vertices: [Vec3]; let edges: [MetalAmboEdge] }
internal struct MetalAmboResult: Sendable { let vertices: [Vec3] }
internal struct MetalKisRequest: Sendable { let vertices: [Vec3]; let faceInfos: [FaceInfo]; let faceIndices: [UInt32]; let parameters: KisParameters }
internal struct MetalKisResult: Sendable { let vertices: [Vec3] }
internal struct MetalReciprocalCRequest: Sendable { let vertices: [Vec3] }
internal struct MetalReciprocalNRequest: Sendable { let vertices: [Vec3]; let faces: [Face] }
internal struct MetalCanonicalizationResult: Sendable { let vertices: [Vec3] }
internal struct MetalDualRequest: Sendable { let vertices: [Vec3]; let faces: [Face] }
internal struct MetalDualResult: Sendable { let vertices: [Vec3] }

/// Owns every framework object required for compute work.
///
/// `MTLDevice`, queues, libraries, pipelines, buffers, encoders, and command
/// buffers stay actor-isolated. The public operations accept and return values.
internal actor MetalExecutor {
    private let availableCapabilities: MetalCapabilities
#if canImport(Metal)
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private var pipelines: [String: MTLComputePipelineState] = [:]
#endif

    init() {
#if canImport(Metal)
        let device = MTLCreateSystemDefaultDevice()
        self.device = device
        self.commandQueue = device?.makeCommandQueue()
        self.availableCapabilities = MetalCapabilities(isAvailable: device != nil && self.commandQueue != nil)
#else
        self.availableCapabilities = .unavailable
#endif
    }

    /// Test-only capability seam that constructs no Metal objects.
    internal init(capabilities: MetalCapabilities) {
        self.availableCapabilities = capabilities
#if canImport(Metal)
        self.device = nil
        self.commandQueue = nil
#endif
    }

    func capabilities() -> MetalCapabilities { availableCapabilities }

    func reflect(_ request: MetalReflectRequest) async throws -> MetalReflectResult {
        try Task.checkCancellation()
        guard !request.vertices.isEmpty else { return MetalReflectResult(vertices: []) }
#if canImport(Metal)
        try requireOwnedMetalState(for: "reflect", unavailableError: .deviceNotFound)
        let input = request.vertices.map(Self.float3)
        let inputBuffer = try makeBuffer(input, label: "reflect input")
        let output: [SIMD3<Float>] = try await execute(function: "reflect_vertex_kernel", inputBuffers: [inputBuffer], inputStart: 0, outputCount: input.count, threads: 64) { encoder, output in
            encoder.setBuffer(output, offset: 0, index: 1)
        }
        return MetalReflectResult(vertices: output.map(Self.vec3))
#else
        throw MetalError.unavailable(capability: "reflect")
#endif
    }

    func ambo(_ request: MetalAmboRequest) async throws -> MetalAmboResult {
        try Task.checkCancellation()
        guard !request.edges.isEmpty else { return MetalAmboResult(vertices: []) }
#if canImport(Metal)
        try requireOwnedMetalState(for: "ambo", unavailableError: .deviceNotFound)
        let vertices = request.vertices.map(Self.float3)
        let vertexBuffer = try makeBuffer(vertices, label: "ambo vertices")
        let edgeBuffer = try makeBuffer(request.edges, label: "ambo edges")
        var parameters = AmboParams(edgeCount: UInt32(request.edges.count), vertexCount: UInt32(vertices.count))
        let output: [SIMD3<Float>] = try await execute(function: "ambo_vertex_kernel", inputBuffers: [vertexBuffer, edgeBuffer], inputStart: 1, outputCount: request.edges.count, threads: 64) { encoder, output in
            encoder.setBytes(&parameters, length: MemoryLayout<AmboParams>.stride, index: 0)
            encoder.setBuffer(output, offset: 0, index: 3)
        }
        return MetalAmboResult(vertices: output.map(Self.vec3))
#else
        throw MetalError.unavailable(capability: "ambo")
#endif
    }

    func kis(_ request: MetalKisRequest) async throws -> MetalKisResult {
        try Task.checkCancellation()
#if canImport(Metal)
        try requireOwnedMetalState(for: "kis", unavailableError: .deviceNotFound)
        let vertices = request.vertices.map(Self.float3)
        let resultCount = vertices.count + request.faceInfos.count
        let vertexBuffer = try makeBuffer(vertices, label: "kis vertices")
        let faceInfoBuffer = try makeBuffer(request.faceInfos, label: "kis face info")
        let indexBuffer = try makeBuffer(request.faceIndices, label: "kis indices")
        var parameters = KisParams(n: Int32(request.parameters.n), apexDistance: Float(request.parameters.apexDistance), faceCount: UInt32(request.faceInfos.count), vertexCount: UInt32(vertices.count))
        let output: [SIMD3<Float>] = try await execute(function: "kis_vertex_kernel", inputBuffers: [vertexBuffer, faceInfoBuffer, indexBuffer], inputStart: 1, outputCount: resultCount, threads: 32, seed: vertices) { encoder, output in
            encoder.setBytes(&parameters, length: MemoryLayout<KisParams>.stride, index: 0)
            encoder.setBuffer(output, offset: 0, index: 4)
        }
        return MetalKisResult(vertices: output.map(Self.vec3))
#else
        throw MetalError.unavailable(capability: "kis")
#endif
    }

    func dual(_ request: MetalDualRequest) async throws -> MetalDualResult {
        try Task.checkCancellation()
        guard !request.faces.isEmpty else { return MetalDualResult(vertices: []) }
#if canImport(Metal)
        try requireOwnedMetalState(for: "dual", unavailableError: .unavailable(capability: "dual"))
        let vertices = request.vertices.map(Self.float3)
        let flattened = flatten(request.faces)
        let vertexBuffer = try makeBuffer(vertices, label: "dual vertices")
        let faceInfoBuffer = try makeBuffer(flattened.ranges.map { FaceInfo(start: $0.start, count: $0.count) }, label: "dual face info")
        let indexBuffer = try makeBuffer(flattened.indices, label: "dual indices")
        var faceCount = UInt32(request.faces.count)
        let output: [SIMD3<Float>] = try await execute(function: "face_centroid_kernel", inputBuffers: [vertexBuffer, faceInfoBuffer, indexBuffer], inputStart: 0, outputCount: request.faces.count, threads: 64) { encoder, output in
            encoder.setBuffer(output, offset: 0, index: 3)
            encoder.setBytes(&faceCount, length: MemoryLayout<UInt32>.stride, index: 4)
        }
        return MetalDualResult(vertices: output.map(Self.vec3))
#else
        throw MetalError.unavailable(capability: "dual")
#endif
    }

    func reciprocalC(_ request: MetalReciprocalCRequest) async throws -> MetalCanonicalizationResult {
        try Task.checkCancellation()
        guard !request.vertices.isEmpty else { return MetalCanonicalizationResult(vertices: []) }
#if canImport(Metal)
        try requireOwnedMetalState(for: "canonicalization", unavailableError: .unavailable(capability: "canonicalization"))
        let vertices = request.vertices.map(Self.float3)
        let input = try makeBuffer(vertices, label: "reciprocal C input")
        var parameters = MetalCanonicalizationScalarParameters(count: UInt32(vertices.count))
        let output: [SIMD3<Float>] = try await execute(function: "reciprocal_c_kernel", inputBuffers: [input], inputStart: 0, outputCount: vertices.count, threads: 64) { encoder, output in
            encoder.setBuffer(output, offset: 0, index: 1)
            encoder.setBytes(&parameters, length: MemoryLayout<MetalCanonicalizationScalarParameters>.stride, index: 2)
        }
        return MetalCanonicalizationResult(vertices: output.map(Self.vec3))
#else
        throw MetalError.unavailable(capability: "canonicalization")
#endif
    }

    func reciprocalN(_ request: MetalReciprocalNRequest) async throws -> MetalCanonicalizationResult {
        try Task.checkCancellation()
        guard !request.vertices.isEmpty, !request.faces.isEmpty else { return MetalCanonicalizationResult(vertices: []) }
#if canImport(Metal)
        try requireOwnedMetalState(for: "canonicalization", unavailableError: .unavailable(capability: "canonicalization"))
        let vertices = request.vertices.map(Self.float3)
        let flattened = flatten(request.faces)
        let vertexBuffer = try makeBuffer(vertices, label: "reciprocal N vertices")
        let rangeBuffer = try makeBuffer(flattened.ranges, label: "reciprocal N ranges")
        let indexBuffer = try makeBuffer(flattened.indices, label: "reciprocal N indices")
        var parameters = MetalCanonicalizationFaceParameters(faceCount: UInt32(request.faces.count), vertexCount: UInt32(vertices.count))
        let output: [SIMD3<Float>] = try await execute(function: "reciprocal_n_kernel", inputBuffers: [vertexBuffer, rangeBuffer, indexBuffer], inputStart: 0, outputCount: request.faces.count, threads: 64) { encoder, output in
            encoder.setBuffer(output, offset: 0, index: 3)
            encoder.setBytes(&parameters, length: MemoryLayout<MetalCanonicalizationFaceParameters>.stride, index: 4)
        }
        return MetalCanonicalizationResult(vertices: output.map(Self.vec3))
#else
        throw MetalError.unavailable(capability: "canonicalization")
#endif
    }

#if canImport(Metal)
    private func requireOwnedMetalState(for _: String, unavailableError: MetalError) throws {
        guard device != nil, commandQueue != nil else { throw unavailableError }
    }

    private func makeBuffer<T>(_ values: [T], label: String) throws -> MTLBuffer {
        guard !values.isEmpty else { throw MetalError.resourceCreation(label) }
        guard let buffer = values.withUnsafeBytes({ bytes in
            device?.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        }) else { throw MetalError.resourceCreation(label) }
        return buffer
    }

    private func pipeline(for functionName: String) throws -> MTLComputePipelineState {
        if let pipeline = pipelines[functionName] { return pipeline }
        guard let device else { throw MetalError.unavailable(capability: functionName) }
        let library = try library(containing: functionName, device: device)
        guard let function = library.makeFunction(name: functionName) else { throw MetalError.functionNotFound(functionName) }
        do {
            let pipeline = try device.makeComputePipelineState(function: function)
            pipelines[functionName] = pipeline
            return pipeline
        } catch { throw MetalError.pipelineCreation(functionName) }
    }

    private func library(containing functionName: String, device: MTLDevice) throws -> MTLLibrary {
        if let library = device.makeDefaultLibrary(), library.makeFunction(name: functionName) != nil { return library }
        for sourceName in Self.kernelSources {
            guard let url = Bundle.module.url(forResource: sourceName, withExtension: "metal"),
                  let source = try? String(contentsOf: url),
                  let library = try? device.makeLibrary(source: source, options: nil),
                  library.makeFunction(name: functionName) != nil else { continue }
            return library
        }
        throw MetalError.libraryNotFound
    }

    private func execute(function: String, inputBuffers: [MTLBuffer], inputStart: Int, outputCount: Int, threads: Int, seed: [SIMD3<Float>] = [], configure: (MTLComputeCommandEncoder, MTLBuffer) -> Void) async throws -> [SIMD3<Float>] {
        guard let commandQueue else { throw MetalError.unavailable(capability: function) }
        let pipeline = try pipeline(for: function)
        guard let output = device?.makeBuffer(length: outputCount * MemoryLayout<SIMD3<Float>>.stride, options: .storageModeShared) else { throw MetalError.resourceCreation("\(function) output") }
        if !seed.isEmpty {
            let pointer = output.contents().bindMemory(to: SIMD3<Float>.self, capacity: outputCount)
            for index in seed.indices { pointer[index] = seed[index] }
        }
        try Task.checkCancellation()
        guard let commandBuffer = commandQueue.makeCommandBuffer(), let encoder = commandBuffer.makeComputeCommandEncoder() else { throw MetalError.resourceCreation("\(function) command encoder") }
        encoder.setComputePipelineState(pipeline)
        for (index, buffer) in inputBuffers.enumerated() { encoder.setBuffer(buffer, offset: 0, index: inputStart + index) }
        configure(encoder, output)
        let threadWidth = min(max(1, pipeline.maxTotalThreadsPerThreadgroup), threads)
        encoder.dispatchThreadgroups(MTLSize(width: (outputCount + threadWidth - 1) / threadWidth, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: threadWidth, height: 1, depth: 1))
        encoder.endEncoding()
        try await commitAndWait(commandBuffer)
        try Task.checkCancellation()
        let pointer = output.contents().bindMemory(to: SIMD3<Float>.self, capacity: outputCount)
        return (0..<outputCount).map { pointer[$0] }
    }

    private func commitAndWait(_ commandBuffer: MTLCommandBuffer) async throws {
        let completion = MetalExecutorCompletionState()
        commandBuffer.addCompletedHandler { buffer in
            let result: MetalExecutorCompletion = buffer.error.map { .failed(.commandFailure(($0 as NSError).localizedDescription)) } ?? .succeeded
            Task { await completion.finish(result) }
        }
        commandBuffer.commit()
        let timeoutTask = Task {
            try? await Task.sleep(for: .seconds(10))
            await completion.finish(.failed(.timeout))
        }
        defer { timeoutTask.cancel() }
        let result = await withTaskCancellationHandler(operation: { await completion.wait() }, onCancel: { Task { await completion.finish(.cancelled) } })
        switch result {
        case .succeeded: return
        case .failed(let error): throw error
        case .cancelled: throw CancellationError()
        }
    }

    private static let kernelSources = ["GeometryKernels", "KisOperatorKernels", "AmboOperatorKernels", "ReflectOperatorKernels", "CanonicalizationKernels"]
    private static func float3(_ value: Vec3) -> SIMD3<Float> { SIMD3(Float(value.x), Float(value.y), Float(value.z)) }
    private static func vec3(_ value: SIMD3<Float>) -> Vec3 { Vec3(Double(value.x), Double(value.y), Double(value.z)) }
#endif

    private func flatten(_ faces: [Face]) -> (ranges: [MetalCanonicalizationFaceRange], indices: [UInt32]) {
        var ranges: [MetalCanonicalizationFaceRange] = []
        var indices: [UInt32] = []
        ranges.reserveCapacity(faces.count)
        for face in faces {
            ranges.append(MetalCanonicalizationFaceRange(start: UInt32(indices.count), count: UInt32(face.count)))
            indices.append(contentsOf: face.map { UInt32(max(0, $0)) })
        }
        return (ranges, indices)
    }
}

internal enum MetalExecutorCompletion: Sendable { case succeeded; case failed(MetalError); case cancelled }

internal actor MetalExecutorCompletionState {
    private var result: MetalExecutorCompletion?
    private var waiters: [CheckedContinuation<MetalExecutorCompletion, Never>] = []
    func wait() async -> MetalExecutorCompletion {
        if let result { return result }
        return await withCheckedContinuation { waiters.append($0) }
    }
    func finish(_ result: MetalExecutorCompletion) {
        guard self.result == nil else { return }
        self.result = result
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume(returning: result) }
    }
}

private struct MetalCanonicalizationScalarParameters { var count: UInt32 }
private struct MetalCanonicalizationFaceParameters { var faceCount: UInt32; var vertexCount: UInt32 }
private struct MetalCanonicalizationFaceRange { var start: UInt32; var count: UInt32 }
