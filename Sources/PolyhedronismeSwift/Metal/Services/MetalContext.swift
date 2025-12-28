//
// PolyhedronismeSwift
// MetalContext.swift
//
// Metal context service for GPU resource management
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
internal final class MetalContext: MetalConfiguration, Sendable {
    let device: MetalDevice?
    let commandQueue: MetalCommandQueue?
    
    init() {
        self.device = MetalWrapper.createSystemDefaultDevice()
        self.commandQueue = self.device?.makeCommandQueue()
    }
    
    func makeBuffer<T>(array: [T], options: MetalResourceOptions = .storageModeShared) -> MetalBuffer? {
        guard let device = device, !array.isEmpty else { return nil }
        return array.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: buffer.count, options: options)
        }
    }
}

