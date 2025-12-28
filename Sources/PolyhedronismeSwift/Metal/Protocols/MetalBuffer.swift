//
// PolyhedronismeSwift
// MetalBuffer.swift
//
// Protocol definition for Metal Buffer abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol MetalBuffer: Sendable {
    func contents() -> UnsafeMutableRawPointer
}

