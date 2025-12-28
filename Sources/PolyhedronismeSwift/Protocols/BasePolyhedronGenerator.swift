//
// PolyhedronismeSwift
// BasePolyhedronGenerator.swift
//
// Protocol definition for BasePolyhedronGenerator in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol BasePolyhedronGenerator: Sendable {
    var identifier: String { get }
    func generate() async throws -> PolyhedronModel
}

internal protocol ParameterizedBasePolyhedronGenerator: Sendable {
    associatedtype Parameters
    var identifier: String { get }
    func generate(parameters: Parameters) async throws -> PolyhedronModel
}

