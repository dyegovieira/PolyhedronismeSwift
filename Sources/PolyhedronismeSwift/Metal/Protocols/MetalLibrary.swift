//
// PolyhedronismeSwift
// MetalLibrary.swift
//
// Protocol definition for Metal Library abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol MetalLibrary: Sendable {
    func makeFunction(name: String) -> MetalFunction?
}

