//
// PolyhedronismeSwift
// MetalComputeCommandEncoder.swift
//
// Protocol definition for Metal ComputeCommandEncoder abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol MetalComputeCommandEncoder: Sendable {
    func setComputePipelineState(_ state: MetalComputePipelineState)
    func setBuffer(_ buffer: MetalBuffer?, offset: Int, index: Int)
    func setBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func dispatchThreadgroups(_ threadgroupsPerGrid: MetalSize, threadsPerThreadgroup: MetalSize)
    func endEncoding()
}

