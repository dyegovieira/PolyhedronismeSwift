//
// PolyhedronismeSwift
// MetalBufferProvider.swift
//
// Metal buffer provider service for GPU memory management
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
internal final class MetalBufferProvider: Sendable {
    private let device: MetalDevice
    
    init?(device: MetalDevice?) {
        guard let device = device else { return nil }
        self.device = device
    }
    
    func makeBuffer<T>(from array: [T], options: MetalResourceOptions = .storageModeShared) -> MetalBuffer? {
        guard !array.isEmpty else { return nil }
        return array.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: buffer.count, options: options)
        }
    }
    
    func makeBuffer(length: Int, options: MetalResourceOptions = .storageModeShared) -> MetalBuffer? {
        return device.makeBuffer(length: length, options: options)
    }
}

