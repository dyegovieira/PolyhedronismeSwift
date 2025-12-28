//
// PolyhedronismeSwift
// KisOperator.swift
//
// Kis operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct KisParameters: Sendable {
    public let n: Int
    public let apexDistance: Double
    
    public init(n: Int = 0, apexDistance: Double = 0.1) {
        self.n = n
        self.apexDistance = apexDistance
    }
}

internal struct KisOperator: ParameterizedPolyhedronOperator {
    public typealias Parameters = KisParameters
    
    public let identifier: String = "k"
    
    private let faceCalculator: FaceCalculator
    
    public init(faceCalculator: FaceCalculator = DefaultFaceCalculator()) {
        self.faceCalculator = faceCalculator
    }
    
    public func apply(to polyhedron: PolyhedronModel, parameters: KisParameters) async throws -> PolyhedronModel {
        let n = parameters.n
        let apexdist = parameters.apexDistance
        
        var flag = PolyFlag()
        for i in 0..<polyhedron.vertices.count {
            let p = polyhedron.vertices[i]
            flag.newV("v\(i)", p)
        }
        
        var cacheablePolyhedron = polyhedron
        let normals = await cacheablePolyhedron.cachedNormals(using: faceCalculator)
        let centers = await cacheablePolyhedron.cachedCenters(using: faceCalculator)
        
        let faceCount = polyhedron.faces.count
        let pendingAssignments = await ParallelExecutor.forEach(count: faceCount) { range in
            var local: [(Int, KisFaceInstruction)] = []
            local.reserveCapacity(range.count)
            for idx in range {
                local.append((
                    idx,
                    KisFaceInstruction.build(
                        index: idx,
                        face: polyhedron.faces[idx],
                        n: n,
                        apexDistance: apexdist,
                        center: centers[idx],
                        normal: normals[idx]
                    )
                ))
            }
            return local
        }
        
        var instructions = Array(repeating: KisFaceInstruction(), count: faceCount)
        for chunk in pendingAssignments {
            for entry in chunk {
                instructions[entry.0] = entry.1
            }
        }
        
        for instruction in instructions {
            for vertex in instruction.newVertices {
                flag.newV(vertex.name, vertex.value)
            }
            for command in instruction.flagCommands {
                flag.newFlag(command.face, command.from, command.to)
            }
        }
        
        let newpoly = flag.topoly()
        let resultModel = PolyhedronModel(
            vertices: newpoly.vertices,
            faces: newpoly.faces,
            name: "k\(n == 0 ? "" : "\(n)")\(polyhedron.name)",
            faceClasses: []
        )
        
        return resultModel
    }
}

private struct KisFaceInstruction {
    var newVertices: [(name: String, value: Vec3)] = []
    var flagCommands: [(face: String, from: String, to: String)] = []
    var usedKis: Bool = false
    
    static func build(
        index: Int,
        face: Face,
        n: Int,
        apexDistance: Double,
        center: Vec3,
        normal: Vec3
    ) -> KisFaceInstruction {
        var instruction = KisFaceInstruction()
        var v1 = "v\(face[face.count - 1])"
        for vertex in face {
            let v2 = "v\(vertex)"
            if (face.count == n) || (n == 0) {
                instruction.usedKis = true
                let apex = "apex\(index)"
                let fname = "\(index)\(v1)"
                let apexVec = Vector3.add(center, Vector3.multiply(apexDistance, normal))
                instruction.newVertices.append((name: apex, value: apexVec))
                instruction.flagCommands.append((face: fname, from: v1, to: v2))
                instruction.flagCommands.append((face: fname, from: v2, to: apex))
                instruction.flagCommands.append((face: fname, from: apex, to: v1))
            } else {
                instruction.flagCommands.append((face: "\(index)", from: v1, to: v2))
            }
            v1 = v2
        }
        return instruction
    }
}

