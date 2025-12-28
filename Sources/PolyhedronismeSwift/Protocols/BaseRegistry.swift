//
// PolyhedronismeSwift
// BaseRegistry.swift
//
// Protocol definition for BaseRegistry in polyhedral generation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol BaseRegistry: Sendable {
    func getBase(for identifier: String) -> BasePolyhedronGenerator?
    func getParameterizedBase<Params: Sendable>(for identifier: String, as type: Params.Type) -> (any ParameterizedBasePolyhedronGenerator)?
    func allBases() -> [String: BasePolyhedronGenerator]
}

