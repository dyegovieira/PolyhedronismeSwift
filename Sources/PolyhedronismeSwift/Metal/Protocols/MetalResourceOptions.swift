//
// PolyhedronismeSwift
// MetalResourceOptions.swift
//
// Protocol definition for Metal ResourceOptions abstraction in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct MetalResourceOptions: OptionSet, Sendable {
    let rawValue: UInt
    
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    static let storageModeShared = MetalResourceOptions([])
}

internal typealias MetalLibraryCompileOptions = Any?

