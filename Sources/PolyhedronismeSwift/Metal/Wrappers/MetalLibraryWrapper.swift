//
// PolyhedronismeSwift
// MetalLibraryWrapper.swift
//
// Metal Library wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalLibraryWrapper: MetalLibrary, Sendable {
    private let library: MTLLibrary
    
    init(library: MTLLibrary) {
        self.library = library
    }
    
    func makeFunction(name: String) -> MetalFunction? {
        guard let function = library.makeFunction(name: name) else { return nil }
        return MetalFunctionWrapper(function: function)
    }
}
#endif

