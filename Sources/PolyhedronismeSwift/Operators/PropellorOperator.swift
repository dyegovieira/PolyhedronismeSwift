//
// PolyhedronismeSwift
// PropellorOperator.swift
//
// Propellor operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct PropellorOperator: PolyhedronOperator {
    public let identifier: String = "p"
    
    public init() {}
    
    public func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        
        var flag = PolyFlag()
        
        for i in 0..<polyhedron.vertices.count {
            let v = polyhedron.vertices[i]
            flag.newV("v\(i)", Vector3.normalize(v))
        }
        
        for i in 0..<polyhedron.faces.count {
            let f = polyhedron.faces[i]
            var v1 = f[f.count - 2]
            var v2 = f[f.count - 1]
            for v3 in f {
                flag.newV("\(v1)~\(v2)", Vector3.oneThird(polyhedron.vertices[v1], polyhedron.vertices[v2]))
                let fname = "\(i)f\(v2)"
                flag.newFlag("v\(i)", "\(v1)~\(v2)", "\(v2)~\(v3)")
                flag.newFlag(fname, "\(v1)~\(v2)", "\(v2)~\(v1)")
                flag.newFlag(fname, "\(v2)~\(v1)", "v\(v2)")
                flag.newFlag(fname, "v\(v2)", "\(v2)~\(v3)")
                flag.newFlag(fname, "\(v2)~\(v3)", "\(v1)~\(v2)")
                v1 = v2
                v2 = v3
            }
        }
        
        let newpoly = flag.topoly()
        let resultModel = PolyhedronModel(
            vertices: newpoly.vertices,
            faces: newpoly.faces,
            name: "p\(polyhedron.name)",
            faceClasses: []
        )
        
        return resultModel
    }
}

