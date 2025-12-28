//
// PolyhedronismeSwift
// StandardBaseRegistry.swift
//
// Base registry for managing polyhedron base generators
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct StandardBaseRegistry {
    public static func makeDefault() -> BaseRegistry {
        var bases: [String: BasePolyhedronGenerator] = [:]
        var parameterizedBases: [String: any ParameterizedBasePolyhedronGenerator] = [:]
        
        bases[TetrahedronGenerator().identifier] = TetrahedronGenerator()
        bases[OctahedronGenerator().identifier] = OctahedronGenerator()
        bases[CubeGenerator().identifier] = CubeGenerator()
        bases[IcosahedronGenerator().identifier] = IcosahedronGenerator()
        bases[DodecahedronGenerator().identifier] = DodecahedronGenerator()
        
        parameterizedBases[PrismGenerator().identifier] = PrismGenerator()
        parameterizedBases[AntiprismGenerator().identifier] = AntiprismGenerator()
        parameterizedBases[PyramidGenerator().identifier] = PyramidGenerator()
        parameterizedBases[CupolaGenerator().identifier] = CupolaGenerator()
        parameterizedBases[AnticupolaGenerator().identifier] = AnticupolaGenerator()
        
        return DefaultBaseRegistry(bases: bases, parameterizedBases: parameterizedBases)
    }
}

