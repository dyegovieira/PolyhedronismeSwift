//
// PolyhedronismeSwift
// PolyhedronModel.swift
//
// PolyhedronModel domain model for representing polyhedral geometry data
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public struct PolyhedronModel: Sendable {
    public var faces: [Face] {
        didSet { invalidateGeometryCache() }
    }
    public var vertices: [Vec3] {
        didSet { invalidateGeometryCache() }
    }
    public var name: String
    public var faceClasses: [Int]
    
    private struct GeometryCache: Sendable {
        var edges: [[Int]]?
        var centers: [Vec3]?
        var normals: [Vec3]?
    }
    
    private var geometryCache = GeometryCache()
    
    public init(
        vertices: [Vec3] = [],
        faces: [Face] = [],
        name: String = "null polyhedron",
        faceClasses: [Int] = []
    ) {
        self.vertices = vertices
        self.faces = faces
        self.name = name
        self.faceClasses = faceClasses
    }
    
    public var isEmpty: Bool {
        vertices.isEmpty || faces.isEmpty
    }
    
    public var vertexCount: Int {
        vertices.count
    }
    
    public var faceCount: Int {
        faces.count
    }
    
    mutating func cachedEdges(using calculator: EdgeCalculator) async -> [[Int]] {
        if let edges = geometryCache.edges {
            return edges
        }
        let computedEdges = await calculator.calculateEdges(from: self)
        geometryCache.edges = computedEdges
        return computedEdges
    }
    
    mutating func cachedCenters(using calculator: FaceCalculator) async -> [Vec3] {
        if let centers = geometryCache.centers {
            return centers
        }
        let computedCenters = await calculator.calculateCenters(from: self)
        geometryCache.centers = computedCenters
        return computedCenters
    }
    
    mutating func cachedNormals(using calculator: FaceCalculator) async -> [Vec3] {
        if let normals = geometryCache.normals {
            return normals
        }
        let computedNormals = await calculator.calculateNormals(from: self)
        geometryCache.normals = computedNormals
        return computedNormals
    }
    
    private mutating func invalidateGeometryCache() {
        geometryCache = GeometryCache()
    }
}

extension PolyhedronModel {
    init(_ polyhedron: Polyhedron) {
        self.init(
            vertices: polyhedron.vertices,
            faces: polyhedron.faces,
            name: polyhedron.name,
            faceClasses: polyhedron.faceClasses
        )
    }
}

