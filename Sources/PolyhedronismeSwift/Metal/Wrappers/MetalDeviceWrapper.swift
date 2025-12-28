//
// PolyhedronismeSwift
// MetalDeviceWrapper.swift
//
// Metal Device wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalDeviceWrapper: MetalDevice, Sendable {
    private let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func makeCommandQueue() -> MetalCommandQueue? {
        guard let queue = device.makeCommandQueue() else { return nil }
        return MetalCommandQueueWrapper(queue: queue)
    }
    
    func makeDefaultLibrary() -> MetalLibrary? {
        guard let library = device.makeDefaultLibrary() else { return nil }
        return MetalLibraryWrapper(library: library)
    }
    
    func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
        let library = try device.makeLibrary(source: source, options: nil)
        return MetalLibraryWrapper(library: library)
    }
    
    func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
        guard let metalFunction = function as? MetalFunctionWrapper else {
            throw MetalError.functionNotFound("unknown")
        }
        let pipeline = try device.makeComputePipelineState(function: metalFunction.function)
        return MetalComputePipelineStateWrapper(pipeline: pipeline)
    }
    
    func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
        let metalOptions = MTLResourceOptions(rawValue: options.rawValue)
        guard let buffer = device.makeBuffer(bytes: bytes, length: length, options: metalOptions) else {
            return nil
        }
        return MetalBufferWrapper(buffer: buffer)
    }
    
    func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
        let metalOptions = MTLResourceOptions(rawValue: options.rawValue)
        guard let buffer = device.makeBuffer(length: length, options: metalOptions) else {
            return nil
        }
        return MetalBufferWrapper(buffer: buffer)
    }
}
#endif

