//
// PolyhedronismeSwift
// GyroOperator.swift
//
// Gyro operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct GyroOperator: PolyhedronOperator {
    public let identifier: String = "g"
    
    private let faceCalculator: FaceCalculator
    
    public init(faceCalculator: FaceCalculator = DefaultFaceCalculator()) {
        self.faceCalculator = faceCalculator
    }
    
    public func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        
        var flag = PolyFlag()
        
        for i in 0..<polyhedron.vertices.count {
            let v = polyhedron.vertices[i]
            flag.newV("v\(i)", Vector3.normalize(v))
        }
        
        var cacheablePolyhedron = polyhedron
        let centers = await cacheablePolyhedron.cachedCenters(using: faceCalculator)
        for i in 0..<polyhedron.faces.count {
            flag.newV("center\(i)", Vector3.normalize(centers[i]))
        }
        
        for i in 0..<polyhedron.faces.count {
            let f = polyhedron.faces[i]
            var v1 = f[f.count - 2]
            var v2 = f[f.count - 1]
            for j in 0..<f.count {
                let v3 = f[j]
                flag.newV("\(v1)~\(v2)", Vector3.oneThird(polyhedron.vertices[v1], polyhedron.vertices[v2]))
                let fname = "\(i)f\(v1)"
                flag.newFlag(fname, "center\(i)", "\(v1)~\(v2)")
                flag.newFlag(fname, "\(v1)~\(v2)", "\(v2)~\(v1)")
                flag.newFlag(fname, "\(v2)~\(v1)", "v\(v2)")
                flag.newFlag(fname, "v\(v2)", "\(v2)~\(v3)")
                flag.newFlag(fname, "\(v2)~\(v3)", "center\(i)")
                v1 = v2
                v2 = v3
            }
        }
        
        let newpoly = flag.topoly()
        let resultModel = PolyhedronModel(
            vertices: newpoly.vertices,
            faces: newpoly.faces,
            name: "g\(polyhedron.name)",
            faceClasses: []
        )
        
        return resultModel
    }
}

