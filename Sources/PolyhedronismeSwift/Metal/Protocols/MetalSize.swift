//
// PolyhedronismeSwift
// MetalSize.swift
//
// Protocol definition for Metal Size abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalSize: Sendable {
    let width: Int
    let height: Int
    let depth: Int
    
    init(width: Int, height: Int = 1, depth: Int = 1) {
        self.width = width
        self.height = height
        self.depth = depth
    }
}

