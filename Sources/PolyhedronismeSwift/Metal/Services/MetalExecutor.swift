//
// MetalExecutor.swift
//
// Keeps the package-facing Metal contract stable while isolating runtime
// Metal availability behind a single actor boundary.
//

import Foundation
import simd

#if canImport(Metal) && !os(watchOS)
import Metal
#endif

struct MetalCapabilities: Sendable, Equatable {
    let isAvailable: Bool

    static let unavailable = MetalCapabilities(isAvailable: false)
}

enum MetalExecutorCompletion: Sendable {
    case succeeded
    case failed(MetalError)
    case cancelled
}

actor MetalExecutorCompletionState {
    private var result: MetalExecutorCompletion?
    private var waiters: [CheckedContinuation<MetalExecutorCompletion, Never>] = []

    func finish(_ completion: MetalExecutorCompletion) {
        guard result == nil else { return }
        result = completion
        let pending = waiters
        waiters.removeAll(keepingCapacity: false)
        for waiter in pending {
            waiter.resume(returning: completion)
        }
    }

    func wait() async -> MetalExecutorCompletion {
        if let result {
            return result
        }
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

struct MetalReflectRequest: Sendable {
    let vertices: [Vec3]
}

struct MetalReflectResult: Sendable {
    let vertices: [Vec3]
}

struct MetalAmboRequest: Sendable {
    let vertices: [Vec3]
    let edges: [MetalAmboEdge]
}

struct MetalAmboResult: Sendable {
    let vertices: [Vec3]
}

struct MetalKisRequest: Sendable {
    let vertices: [Vec3]
    let faceInfos: [FaceInfo]
    let faceIndices: [UInt32]
    let parameters: KisParameters
}

struct MetalKisResult: Sendable {
    let vertices: [Vec3]
}

struct MetalDualRequest: Sendable {
    let vertices: [Vec3]
    let faces: [Face]
}

struct MetalDualResult: Sendable {
    let vertices: [Vec3]
}

struct MetalReciprocalCRequest: Sendable {
    let vertices: [Vec3]
}

struct MetalReciprocalCResult: Sendable {
    let vertices: [Vec3]
}

struct MetalReciprocalNRequest: Sendable {
    let vertices: [Vec3]
    let faces: [Face]
}

struct MetalReciprocalNResult: Sendable {
    let vertices: [Vec3]
}

actor MetalExecutor {
    private let injectedCapabilities: MetalCapabilities?
    private let runtimeCapabilities: MetalCapabilities

    #if canImport(Metal) && !os(watchOS)
    private let device: MTLDevice?
    #endif

    init() {
        self.injectedCapabilities = nil

        #if canImport(Metal) && !os(watchOS)
        let device = MTLCreateSystemDefaultDevice()
        self.device = device
        if let device, device.supportsFamily(.metal4) {
            self.runtimeCapabilities = MetalCapabilities(isAvailable: true)
        } else {
            self.runtimeCapabilities = .unavailable
        }
        #else
        self.runtimeCapabilities = .unavailable
        #endif
    }

    init(capabilities: MetalCapabilities) {
        self.injectedCapabilities = capabilities
        self.runtimeCapabilities = capabilities
        #if canImport(Metal) && !os(watchOS)
        self.device = nil
        #endif
    }

    func capabilities() -> MetalCapabilities {
        injectedCapabilities ?? runtimeCapabilities
    }

    func reflect(_ request: MetalReflectRequest) async throws -> MetalReflectResult {
        try ensureDeviceBackedAvailability(or: .deviceNotFound)
        let vertices = request.vertices.map { -$0 }
        return MetalReflectResult(vertices: vertices)
    }

    func ambo(_ request: MetalAmboRequest) async throws -> MetalAmboResult {
        try ensureDeviceBackedAvailability(or: .deviceNotFound)
        let vertices = request.edges.map { edge in
            let v1 = request.vertices[safe: Int(edge.v1)] ?? .zero()
            let v2 = request.vertices[safe: Int(edge.v2)] ?? .zero()
            return (v1 + v2) * 0.5
        }
        return MetalAmboResult(vertices: vertices)
    }

    func kis(_ request: MetalKisRequest) async throws -> MetalKisResult {
        try ensureDeviceBackedAvailability(or: .deviceNotFound)

        var result = request.vertices
        result.reserveCapacity(request.vertices.count + request.faceInfos.count)

        for faceInfo in request.faceInfos {
            let indices = faceVertices(for: faceInfo, in: request.faceIndices)
            let faceVertices = indices.compactMap { request.vertices[safe: Int($0)] }

            guard faceVertices.count >= 3 else {
                result.append(.zero())
                continue
            }

            let centroid = faceVertices.reduce(into: Vec3.zero(), +=) / Double(faceVertices.count)
            let normal = normalizedFaceNormal(faceVertices)
            let apex = centroid + normal * request.parameters.apexDistance
            result.append(apex)
        }

        return MetalKisResult(vertices: result)
    }

    func dual(_ request: MetalDualRequest) async throws -> MetalDualResult {
        try ensureAvailability(for: "dual")

        let centroids = request.faces.map { face -> Vec3 in
            let vertices = face.compactMap { request.vertices[safe: $0] }
            guard !vertices.isEmpty else { return .zero() }
            return vertices.reduce(into: Vec3.zero(), +=) / Double(vertices.count)
        }

        return MetalDualResult(vertices: centroids)
    }

    func reciprocalC(_ request: MetalReciprocalCRequest) async throws -> MetalReciprocalCResult {
        try ensureAvailability(for: "canonicalization")
        let vertices = CanonicalizationMath.reciprocalC(vertices: ContiguousArray(request.vertices))
        return MetalReciprocalCResult(vertices: Array(vertices))
    }

    func reciprocalN(_ request: MetalReciprocalNRequest) async throws -> MetalReciprocalNResult {
        try ensureAvailability(for: "canonicalization")
        let vertices = CanonicalizationMath.reciprocalN(
            vertices: ContiguousArray(request.vertices),
            faces: request.faces
        )
        return MetalReciprocalNResult(vertices: Array(vertices))
    }

    private func ensureDeviceBackedAvailability(or error: MetalError) throws {
        guard runtimeCapabilities.isAvailable else {
            throw error
        }
    }

    private func ensureAvailability(for capability: String) throws {
        guard runtimeCapabilities.isAvailable else {
            throw MetalError.unavailable(capability: capability)
        }
    }

    private func faceVertices(for info: FaceInfo, in flattened: [UInt32]) -> ArraySlice<UInt32> {
        let start = Int(info.start)
        let end = start + Int(info.count)
        guard start >= 0, end <= flattened.count else { return [] }
        return flattened[start..<end]
    }

    private func normalizedFaceNormal(_ vertices: [Vec3]) -> Vec3 {
        var normal = Vec3.zero()
        let count = vertices.count
        for index in vertices.indices {
            let current = vertices[index]
            let next = vertices[(index + 1) % count]
            normal.x += (current.y - next.y) * (current.z + next.z)
            normal.y += (current.z - next.z) * (current.x + next.x)
            normal.z += (current.x - next.x) * (current.y + next.y)
        }

        let length = simd_length(normal)
        guard length > 0 else { return .zero() }
        return normal / length
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
