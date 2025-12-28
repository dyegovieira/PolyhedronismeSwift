//
// PolyhedronismeSwift
// MetalFunctionWrapper.swift
//
// Metal Function wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalFunctionWrapper: MetalFunction, Sendable {
    let function: MTLFunction
    
    init(function: MTLFunction) {
        self.function = function
    }
}
#endif

