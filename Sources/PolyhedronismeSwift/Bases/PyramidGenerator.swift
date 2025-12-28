//
// PolyhedronismeSwift
// PyramidGenerator.swift
//
// Pyramid base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct PyramidParameters: Sendable {
    public let n: Int
    
    public init(n: Int) {
        self.n = n
    }
}

internal struct PyramidGenerator: ParameterizedBasePolyhedronGenerator {
    public typealias Parameters = PyramidParameters
    
    public let identifier: String = "Y"
    private let canonicalizer: PolyhedronCanonicalizer
    
    public init(canonicalizer: PolyhedronCanonicalizer = DefaultPolyhedronCanonicalizer()) {
        self.canonicalizer = canonicalizer
    }
    
    public func generate(parameters: PyramidParameters) async throws -> PolyhedronModel {
        let poly = await buildPyramid(parameters.n)
        return PolyhedronModel(
            vertices: poly.vertices,
            faces: poly.faces,
            name: poly.name,
            faceClasses: poly.faceClasses
        )
    }
    
    private func buildPyramid(_ n: Int) async -> Polyhedron {
        let theta = 2 * GeometryConstants.pi / Double(n)
        let height = 1.0
        var poly = Polyhedron()
        poly.name = "Y\(n)"
        for i in 0..<n {
            let a = Double(i) * theta
            poly.vertices.append([-cos(a), -sin(a), -0.2])
        }
        poly.vertices.append([0,0,height])
        poly.faces.append(__range__(n-1, 0, true))
        for i in 0..<n {
            poly.faces.append([i, (i+1)%n, n])
        }
        return await canonicalizer.canonicalize(poly, iterations: 3)
    }
}

