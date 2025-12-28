//
// PolyhedronismeSwift
// MetalDevice.swift
//
// Protocol definition for Metal Device abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol MetalDevice: Sendable {
    func makeCommandQueue() -> MetalCommandQueue?
    func makeDefaultLibrary() -> MetalLibrary?
    func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary
    func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState
    func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer?
    func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer?
}

