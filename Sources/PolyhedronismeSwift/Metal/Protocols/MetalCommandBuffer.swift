//
// PolyhedronismeSwift
// MetalCommandBuffer.swift
//
// Protocol definition for Metal CommandBuffer abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol MetalCommandBuffer: Sendable {
    func makeComputeCommandEncoder() -> MetalComputeCommandEncoder?
    func commit()
    func completed() async
}

