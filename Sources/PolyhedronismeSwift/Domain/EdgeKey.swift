//
// PolyhedronismeSwift
// EdgeKey.swift
//
// EdgeKey domain model for polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-17
// Built with AI-assisted development via Cursor IDE
//
import Foundation

struct EdgeKey: Hashable, Sendable {
    let lower: Int
    let upper: Int
    
    init(_ first: Int, _ second: Int) {
        if first <= second {
            self.lower = first
            self.upper = second
        } else {
            self.lower = second
            self.upper = first
        }
    }
}

