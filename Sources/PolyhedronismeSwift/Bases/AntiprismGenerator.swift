//
// PolyhedronismeSwift
// AntiprismGenerator.swift
//
// Antiprism base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct AntiprismParameters: Sendable {
    public let n: Int
    
    public init(n: Int) {
        self.n = n
    }
}

internal struct AntiprismGenerator: ParameterizedBasePolyhedronGenerator {
    public typealias Parameters = AntiprismParameters
    
    public let identifier: String = "A"
    private let canonicalizer: PolyhedronCanonicalizer
    
    public init(canonicalizer: PolyhedronCanonicalizer = DefaultPolyhedronCanonicalizer()) {
        self.canonicalizer = canonicalizer
    }
    
    public func generate(parameters: AntiprismParameters) async throws -> PolyhedronModel {
        let poly = await buildAntiprism(parameters.n)
        return PolyhedronModel(
            vertices: poly.vertices,
            faces: poly.faces,
            name: poly.name,
            faceClasses: poly.faceClasses
        )
    }
    
    private func buildAntiprism(_ n: Int) async -> Polyhedron {
        let theta = 2 * GeometryConstants.pi / Double(n)
        var h = sqrt(1 - (4 / ((4 + (2 * cos(theta/2))) - (2 * cos(theta)))))
        var r = sqrt(1 - (h * h))
        let f = sqrt((h*h) + pow(r * cos(theta/2), 2))
        r = -r / f
        h = -h / f
        var poly = Polyhedron()
        poly.name = "A\(n)"
        for i in 0..<n {
            let a = Double(i) * theta
            poly.vertices.append([r * cos(a), r * sin(a), h])
        }
        for i in 0..<n {
            let a = (Double(i) + 0.5) * theta
            poly.vertices.append([r * cos(a), r * sin(a), -h])
        }
        poly.faces.append(__range__(n-1, 0, true))
        poly.faces.append(__range__(n, (2*n)-1, true))
        for i in 0..<n {
            poly.faces.append([i, (i+1)%n, i+n])
            poly.faces.append([i, i+n, (((n+i)-1)%n)+n])
        }
        return await canonicalizer.adjust(poly, iterations: 1)
    }
}

