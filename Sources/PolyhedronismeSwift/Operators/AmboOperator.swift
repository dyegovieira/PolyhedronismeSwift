//
// PolyhedronismeSwift
// AmboOperator.swift
//
// Ambo operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct AmboOperator: PolyhedronOperator {
    public let identifier: String = "a"
    
    public init() {}
    
    public func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        var flag = PolyFlag()
        
        for i in 0..<polyhedron.faces.count {
            let f = polyhedron.faces[i]
            var v1 = f[f.count - 2]
            var v2 = f[f.count - 1]
            for v3 in f {
                if v1 < v2 {
                    flag.newV(midName(v1, v2), Vector3.midpoint(polyhedron.vertices[v1], polyhedron.vertices[v2]))
                }
                flag.newFlag("orig\(i)", midName(v1, v2), midName(v2, v3))
                flag.newFlag("dual\(v2)", midName(v2, v3), midName(v1, v2))
                v1 = v2
                v2 = v3
            }
        }
        
        let newpoly = flag.topoly()
        let resultModel = PolyhedronModel(
            vertices: newpoly.vertices,
            faces: newpoly.faces,
            name: "a\(polyhedron.name)",
            faceClasses: []
        )
        
        return resultModel
    }
    
    private func midName(_ v1: Int, _ v2: Int) -> String {
        return v1 < v2 ? "\(v1)_\(v2)" : "\(v2)_\(v1)"
    }
}

