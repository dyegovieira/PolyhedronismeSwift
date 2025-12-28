//
// PolyhedronismeSwift
// PrismGenerator.swift
//
// Prism base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct PrismParameters: Sendable {
    public let n: Int
    
    public init(n: Int) {
        self.n = n
    }
}

internal struct PrismGenerator: ParameterizedBasePolyhedronGenerator {
    public typealias Parameters = PrismParameters
    
    public let identifier: String = "P"
    private let canonicalizer: PolyhedronCanonicalizer
    
    public init(canonicalizer: PolyhedronCanonicalizer = DefaultPolyhedronCanonicalizer()) {
        self.canonicalizer = canonicalizer
    }
    
    public func generate(parameters: PrismParameters) async throws -> PolyhedronModel {
        let poly = await buildPrism(parameters.n)
        return PolyhedronModel(
            vertices: poly.vertices,
            faces: poly.faces,
            name: poly.name,
            faceClasses: poly.faceClasses
        )
    }
    
    private func buildPrism(_ n: Int) async -> Polyhedron {
        let theta = 2 * GeometryConstants.pi / Double(n)
        let h = sin(theta / 2)
        var poly = Polyhedron()
        poly.name = "P\(n)"
        for i in 0..<n {
            let a = Double(i) * theta
            poly.vertices.append([-cos(a), -sin(a), -h])
        }
        for i in 0..<n {
            let a = Double(i) * theta
            poly.vertices.append([-cos(a), -sin(a), h])
        }
        poly.faces.append(__range__(n-1, 0, true))
        poly.faces.append(__range__(n, 2*n, false))
        for i in 0..<n {
            poly.faces.append([i, (i+1)%n, ((i+1)%n)+n, i+n])
        }
        return await canonicalizer.adjust(poly, iterations: 1)
    }
}

