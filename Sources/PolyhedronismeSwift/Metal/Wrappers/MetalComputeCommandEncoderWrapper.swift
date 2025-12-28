//
// PolyhedronismeSwift
// MetalComputeCommandEncoderWrapper.swift
//
// Metal ComputeCommandEncoder wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalComputeCommandEncoderWrapper: MetalComputeCommandEncoder, Sendable {
    private let encoder: MTLComputeCommandEncoder
    
    init(encoder: MTLComputeCommandEncoder) {
        self.encoder = encoder
    }
    
    func setComputePipelineState(_ state: MetalComputePipelineState) {
        guard let wrapper = state as? MetalComputePipelineStateWrapper else { return }
        encoder.setComputePipelineState(wrapper.pipeline)
    }
    
    func setBuffer(_ buffer: MetalBuffer?, offset: Int, index: Int) {
        guard let wrapper = buffer as? MetalBufferWrapper else {
            encoder.setBuffer(nil, offset: offset, index: index)
            return
        }
        encoder.setBuffer(wrapper.buffer, offset: offset, index: index)
    }
    
    func setBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        encoder.setBytes(bytes, length: length, index: index)
    }
    
    func dispatchThreadgroups(_ threadgroupsPerGrid: MetalSize, threadsPerThreadgroup: MetalSize) {
        let metalThreadgroups = MTLSize(
            width: threadgroupsPerGrid.width,
            height: threadgroupsPerGrid.height,
            depth: threadgroupsPerGrid.depth
        )
        let metalThreads = MTLSize(
            width: threadsPerThreadgroup.width,
            height: threadsPerThreadgroup.height,
            depth: threadsPerThreadgroup.depth
        )
        encoder.dispatchThreadgroups(metalThreadgroups, threadsPerThreadgroup: metalThreads)
    }
    
    func endEncoding() {
        encoder.endEncoding()
    }
}
#endif

