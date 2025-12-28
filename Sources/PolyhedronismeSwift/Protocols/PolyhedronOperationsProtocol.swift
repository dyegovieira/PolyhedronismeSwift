//
// PolyhedronismeSwift
// PolyhedronOperationsProtocol.swift
//
// Protocol definition for PolyhedronOperationsProtocol in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol PolyhedronOperationsProtocol: Sendable {
    func recenter(_ model: PolyhedronModel, edgeCalculator: EdgeCalculator) async -> PolyhedronModel
    func rescale(_ model: PolyhedronModel) -> PolyhedronModel
}

