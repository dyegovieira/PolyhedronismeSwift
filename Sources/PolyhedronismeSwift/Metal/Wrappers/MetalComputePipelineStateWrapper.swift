//
// PolyhedronismeSwift
// MetalComputePipelineStateWrapper.swift
//
// Metal ComputePipelineState wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalComputePipelineStateWrapper: MetalComputePipelineState, Sendable {
    let pipeline: MTLComputePipelineState
    
    init(pipeline: MTLComputePipelineState) {
        self.pipeline = pipeline
    }
    
    var maxTotalThreadsPerThreadgroup: Int {
        pipeline.maxTotalThreadsPerThreadgroup
    }
}
#endif

