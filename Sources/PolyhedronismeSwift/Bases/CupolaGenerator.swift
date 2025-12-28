//
// PolyhedronismeSwift
// CupolaGenerator.swift
//
// Cupola base polyhedron generator for Conway notation
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct CupolaParameters: Sendable {
    public let n: Int
    public let alpha: Double?
    public let height: Double?
    
    public init(n: Int, alpha: Double? = nil, height: Double? = nil) {
        self.n = n
        self.alpha = alpha
        self.height = height
    }
}

internal struct CupolaGenerator: ParameterizedBasePolyhedronGenerator {
    public typealias Parameters = CupolaParameters
    
    public let identifier: String = "U"
    
    public init() {}
    
    public func generate(parameters: CupolaParameters) async throws -> PolyhedronModel {
        let poly = buildCupola(parameters.n, parameters.alpha, parameters.height)
        return PolyhedronModel(
            vertices: poly.vertices,
            faces: poly.faces,
            name: poly.name,
            faceClasses: poly.faceClasses
        )
    }
    
    private func buildCupola(_ n: Int, _ alpha: Double? = nil, _ heightIn: Double? = nil) -> Polyhedron {
        var poly = Polyhedron()
        poly.name = "U\(n)"
        let alpha = alpha ?? 0.0
        let s = 1.0
        let rb = s / 2 / sin(GeometryConstants.pi / 2 / Double(n))
        let rt = s / 2 / sin(GeometryConstants.pi / Double(n))
        
        let height: Double
        if let h = heightIn {
            height = h
        } else {
            var h = (rb - rt)
            if (2 <= n && n <= 5) {
                h = s * sqrt(1 - 1 / 4 / pow(sin(GeometryConstants.pi/Double(n)), 2))
            }
            height = h
        }
        for _ in 0..<(3*n) { poly.vertices.append([0,0,0]) }
        for i in 0..<n {
            poly.vertices[2*i] = [rb * cos(GeometryConstants.pi*(2*Double(i))/Double(n) + GeometryConstants.pi/2/Double(n)+alpha),
                              rb * sin(GeometryConstants.pi*(2*Double(i))/Double(n) + GeometryConstants.pi/2/Double(n)+alpha),
                              0.0]
            poly.vertices[2*i+1] = [rb * cos(GeometryConstants.pi*(2*Double(i)+1)/Double(n) + GeometryConstants.pi/2/Double(n)-alpha),
                                rb * sin(GeometryConstants.pi*(2*Double(i)+1)/Double(n) + GeometryConstants.pi/2/Double(n)-alpha),
                                0.0]
            poly.vertices[2*n+i] = [rt * cos(2*GeometryConstants.pi*Double(i)/Double(n)),
                                rt * sin(2*GeometryConstants.pi*Double(i)/Double(n)),
                                height]
        }
        poly.faces.append(__range__(2*n-1, 0, true))
        poly.faces.append(__range__(2*n, 3*n-1, true))
        for i in 0..<n {
            poly.faces.append([ (2*i+1)%(2*n), (2*i+2)%(2*n), 2*n+((i+1)%n) ])
            poly.faces.append([ 2*i, (2*i+1)%(2*n), 2*n+((i+1)%n), 2*n+i ])
        }
        return poly
    }
}

