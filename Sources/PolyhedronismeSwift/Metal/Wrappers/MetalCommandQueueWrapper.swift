//
// PolyhedronismeSwift
// MetalCommandQueueWrapper.swift
//
// Metal CommandQueue wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalCommandQueueWrapper: MetalCommandQueue, Sendable {
    private let queue: MTLCommandQueue
    
    init(queue: MTLCommandQueue) {
        self.queue = queue
    }
    
    func makeCommandBuffer() -> MetalCommandBuffer? {
        guard let buffer = queue.makeCommandBuffer() else { return nil }
        return MetalCommandBufferWrapper(buffer: buffer)
    }
}
#endif

