//
// PolyhedronismeSwift
// OperatorRegistry.swift
//
// Protocol definition for OperatorRegistry in polyhedral generation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol OperatorRegistry: Sendable {
    func getOperator(for identifier: String) -> PolyhedronOperator?
    func allOperators() -> [String: PolyhedronOperator]
}

