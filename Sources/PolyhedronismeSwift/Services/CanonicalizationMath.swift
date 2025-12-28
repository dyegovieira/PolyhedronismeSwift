//
// PolyhedronismeSwift
// CanonicalizationMath.swift
//
// CanonicalizationMath service implementation for polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-17
// Built with AI-assisted development via Cursor IDE
//
import Foundation
import simd

struct CanonicalizationMath {
    static func reciprocalC(vertices: ContiguousArray<Vec3>) -> ContiguousArray<Vec3> {
        guard !vertices.isEmpty else { return ContiguousArray() }
        var output = ContiguousArray<Vec3>()
        output.reserveCapacity(vertices.count)
        for vertex in vertices {
            let mag2 = simd_length_squared(vertex)
            if mag2 > 0 {
                output.append(vertex / mag2)
            } else {
                output.append(Vec3.zero())
            }
        }
        return output
    }
    
    static func reciprocalN(vertices: ContiguousArray<Vec3>, faces: [Face]) -> ContiguousArray<Vec3> {
        guard !faces.isEmpty else { return ContiguousArray() }
        var output = ContiguousArray<Vec3>()
        output.reserveCapacity(faces.count)
        
        for face in faces {
            guard face.count >= 3 else {
                output.append(Vec3.zero())
                continue
            }
            var centroid = Vec3.zero()
            var normalV = Vec3.zero()
            var avgEdgeDist = 0.0
            var v1Index = face[face.count - 2]
            var v2Index = face[face.count - 1]
            
            for v3Index in face {
                guard vertices.indices.contains(v1Index),
                      vertices.indices.contains(v2Index),
                      vertices.indices.contains(v3Index) else {
                    continue
                }
                let v1 = vertices[v1Index]
                let v2 = vertices[v2Index]
                let v3 = vertices[v3Index]
                centroid += v3
                normalV += GeometryUtils.orthogonal(v1, v2, v3)
                avgEdgeDist += GeometryUtils.edgeDistance(v1, v2)
                v1Index = v2Index
                v2Index = v3Index
            }
            
            let invCount = 1.0 / Double(face.count)
            centroid *= invCount
            normalV = Vector3.normalize(normalV)
            avgEdgeDist *= invCount
            let scale = simd_dot(centroid, normalV)
            let scaledNormal = normalV * scale
            let tmp = Vector3.reciprocal(scaledNormal)
            output.append(((1.0 + avgEdgeDist) * 0.5) * tmp)
        }
        
        return output
    }
}

