//
// PolyhedronismeSwift
// MetalBufferWrapper.swift
//
// Metal Buffer wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalBufferWrapper: MetalBuffer, Sendable {
    let buffer: MTLBuffer
    
    init(buffer: MTLBuffer) {
        self.buffer = buffer
    }
    
    func contents() -> UnsafeMutableRawPointer {
        buffer.contents()
    }
}
#endif

