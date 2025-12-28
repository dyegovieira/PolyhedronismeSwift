//
// PolyhedronismeSwift
// OBJExporter.swift
//
// OBJ export functionality for polyhedron data
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct OBJExporter: PolyhedronExporter {
    private let faceCalculator: FaceCalculator
    
    internal init(faceCalculator: FaceCalculator = DefaultFaceCalculator()) {
        self.faceCalculator = faceCalculator
    }
    
    internal func export(_ polyhedron: PolyhedronModel) async throws -> String {
        var objstr = "#Produced by polyHédronisme http://levskaya.github.com/polyhedronisme\n"
        objstr += "group \(polyhedron.name)\n"
        objstr += "#vertices\n"
        for v in polyhedron.vertices {
            objstr += "v \(v[0]) \(v[1]) \(v[2])\n"
        }
        objstr += "#normal vector defs \n"
        var cacheableModel = polyhedron
        let normals = await cacheableModel.cachedNormals(using: faceCalculator)
        for norm in normals {
            objstr += "vn \(norm[0]) \(norm[1]) \(norm[2])\n"
        }
        objstr += "#face defs \n"
        for i in 0..<polyhedron.faces.count {
            let f = polyhedron.faces[i]
            objstr += "f "
            for v in f {
                objstr += "\(v+1)//\(i+1) "
            }
            objstr += "\n"
        }
        return objstr
    }
}

