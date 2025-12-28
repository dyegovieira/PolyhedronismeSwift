//
// PolyhedronismeSwift
// DefaultBaseRegistry.swift
//
// Base registry for managing polyhedron base generators
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultBaseRegistry: BaseRegistry {
    private let bases: [String: BasePolyhedronGenerator]
    private let parameterizedBases: [String: any ParameterizedBasePolyhedronGenerator]
    
    public init() {
        self.bases = [:]
        self.parameterizedBases = [:]
    }
    
    public init(
        bases: [String: BasePolyhedronGenerator],
        parameterizedBases: [String: any ParameterizedBasePolyhedronGenerator] = [:]
    ) {
        self.bases = bases
        self.parameterizedBases = parameterizedBases
    }
    
    public func getBase(for identifier: String) -> BasePolyhedronGenerator? {
        bases[identifier]
    }
    
    public func getParameterizedBase<Params: Sendable>(for identifier: String, as type: Params.Type) -> (any ParameterizedBasePolyhedronGenerator)? {
        guard let base = parameterizedBases[identifier] else { return nil }
        return base
    }
    
    public func allBases() -> [String: BasePolyhedronGenerator] {
        bases
    }
}

