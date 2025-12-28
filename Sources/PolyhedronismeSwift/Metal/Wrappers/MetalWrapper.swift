//
// PolyhedronismeSwift
// MetalWrapper.swift
//
// Metal wrapper for centralized GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

internal enum MetalWrapper {
    static func createSystemDefaultDevice() -> MetalDevice? {
        #if canImport(Metal)
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        return MetalDeviceWrapper(device: device)
        #else
        return nil
        #endif
    }
}

