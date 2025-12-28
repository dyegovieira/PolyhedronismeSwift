//
// PolyhedronismeSwift
// MetalCommandBufferWrapper.swift
//
// Metal CommandBuffer wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalCommandBufferWrapper: MetalCommandBuffer, Sendable {
    private let buffer: MTLCommandBuffer
    
    init(buffer: MTLCommandBuffer) {
        self.buffer = buffer
    }
    
    func makeComputeCommandEncoder() -> MetalComputeCommandEncoder? {
        guard let encoder = buffer.makeComputeCommandEncoder() else { return nil }
        return MetalComputeCommandEncoderWrapper(encoder: encoder)
    }
    
    func commit() {
        buffer.commit()
    }
    
    func completed() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                self.buffer.waitUntilCompleted()
                continuation.resume()
            }
        }
    }
}
#endif

