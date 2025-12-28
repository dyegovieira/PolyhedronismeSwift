//
// PolyhedronismeSwift
// AnticupolaGenerator.swift
//
// Anticupola base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct AnticupolaParameters: Sendable {
    public let n: Int
    public let alpha: Double?
    public let height: Double?
    
    public init(n: Int, alpha: Double? = nil, height: Double? = nil) {
        self.n = n
        self.alpha = alpha
        self.height = height
    }
}

internal struct AnticupolaGenerator: ParameterizedBasePolyhedronGenerator {
    public typealias Parameters = AnticupolaParameters
    
    public let identifier: String = "V"
    
    public init() {}
    
    public func generate(parameters: AnticupolaParameters) async throws -> PolyhedronModel {
        let poly = buildAnticupola(parameters.n, parameters.alpha, parameters.height)
        return PolyhedronModel(
            vertices: poly.vertices,
            faces: poly.faces,
            name: poly.name,
            faceClasses: poly.faceClasses
        )
    }
    
    private func buildAnticupola(_ n: Int, _ alpha: Double? = nil, _ heightIn: Double? = nil) -> Polyhedron {
        let alpha = alpha ?? 0.0
        let height = heightIn
        var poly = Polyhedron()
        poly.name = "V\(n)"
        if n < 3 { return poly }
        let s = 1.0
        let rb = s / 2 / sin(GeometryConstants.pi / 2 / Double(n))
        let rt = s / 2 / sin(GeometryConstants.pi / Double(n))
        for _ in 0..<(3*n) { poly.vertices.append([0,0,0]) }
        for i in 0..<n {
            poly.vertices[2*i] = [rb * cos(GeometryConstants.pi*(2*Double(i))/Double(n) + alpha),
                              rb * sin(GeometryConstants.pi*(2*Double(i))/Double(n) + alpha),
                              0.0]
            poly.vertices[2*i+1] = [rb * cos(GeometryConstants.pi*(2*Double(i)+1)/Double(n) - alpha),
                                rb * sin(GeometryConstants.pi*(2*Double(i)+1)/Double(n) - alpha),
                                0.0]
            poly.vertices[2*n+i] = [rt * cos(2*GeometryConstants.pi*Double(i)/Double(n)),
                                rt * sin(2*GeometryConstants.pi*Double(i)/Double(n)),
                                height ?? (rb - rt)]
        }
        poly.faces.append(__range__(2*n-1, 0, true))
        poly.faces.append(__range__(2*n, 3*n-1, true))
        for i in 0..<n {
            poly.faces.append([ (2*i)%(2*n), (2*i+1)%(2*n), 2*n+(i)%n ])
            poly.faces.append([ 2*n+((i+1)%n), (2*i+1)%(2*n), (2*i+2)%(2*n) ])
            poly.faces.append([ 2*n+((i+1)%n), 2*n+(i)%n, (2*i+1)%(2*n) ])
        }
        return poly
    }
}

