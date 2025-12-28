//
// PolyhedronismeSwift
// MetalConfiguration.swift
//
// Protocol definition for Metal Configuration abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
internal protocol MetalConfiguration: Sendable {
    var device: MetalDevice? { get }
    var commandQueue: MetalCommandQueue? { get }
    func makeBuffer<T>(array: [T], options: MetalResourceOptions) -> MetalBuffer?
}

