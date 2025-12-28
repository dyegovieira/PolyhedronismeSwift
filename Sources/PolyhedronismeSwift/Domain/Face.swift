//
// PolyhedronismeSwift
// Face.swift
//
// Face domain model for polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public typealias Face = [Int]

extension Face {
    public func isValid(vertexCount: Int) -> Bool {
        guard count >= 3 else { return false }
        return allSatisfy { $0 >= 0 && $0 < vertexCount }
    }
    
    public func hasDuplicates() -> Bool {
        Set(self).count != count
    }
}

