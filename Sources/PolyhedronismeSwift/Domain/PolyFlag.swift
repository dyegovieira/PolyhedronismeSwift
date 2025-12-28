//
// PolyhedronismeSwift
// PolyFlag.swift
//
// PolyFlag domain model for representing polyhedral flag structures
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

//===================================================================================================
// Polyhedron Flagset Construct
//
// A Flag is an associative triple of a face index and two adjacent vertex vertidxs,
// listed in geometric clockwise order (staring into the normal)
//
// Face_i -> V_i -> V_j
//
// They are a useful abstraction for defining topological transformations of the polyhedral mesh, as
// one can refer to vertices and faces that don't yet exist or haven't been traversed yet in the
// transformation code.
//
// A flag is similar in concept to a directed halfedge in halfedge data structures.
//
let MAX_FACE_SIDEDNESS = 1000

struct PolyFlag: Sendable {
    private static let jsUndefined = "undefined"
    
    var flags = OrderedMap<String, OrderedMap<String, String>>()
    var vertidxs: [String: Int] = [:]
    var verticesMap = OrderedMap<String, Vec3>()
    
    mutating func newV(_ vertName: String, _ coordinates: Vec3) {
        if verticesMap[vertName] == nil {
            verticesMap[vertName] = coordinates
        }
    }
    
    mutating func newFlag(_ faceName: String, _ vertName1: String, _ vertName2: String) {
        if flags[faceName] == nil {
            flags[faceName] = OrderedMap<String, String>()
        }
        flags[faceName]?[vertName1] = vertName2
    }
    
    func faceNamesInOrder() -> [String] {
        flags.keysInserted
    }
    
    func topoly() -> Polyhedron {
        var vertices: [Vec3] = []
        var vertidxsMap: [String: Int] = [:]
        var idx = 0
        for name in verticesMap.keysInserted {
            if let p = verticesMap[name] {
                vertices.append(p)
                vertidxsMap[name] = idx
                idx += 1
            }
        }
        
        var faces: [Face] = []
        var created = 0
        var dropped = 0
        
        for faceName in flags.keysInserted {
            guard let faceMap = flags[faceName] else { continue }
            guard let v0 = faceMap.valuesInserted.first else { continue }
            var newFace: [Int] = []
            var faceCTR = 0
            var v = v0
            var visitedStart = false
            while true {
                if v == Self.jsUndefined { break }
                if let idx = vertidxsMap[v] { newFace.append(idx) }
                guard let next = faceMap[v] else { break }
                v = next
                faceCTR += 1
                if v == v0 { visitedStart = true; break }
                if faceCTR > MAX_FACE_SIDEDNESS { break }
            }
            if visitedStart && newFace.count >= 3 {
                faces.append(newFace)
                created += 1
            } else {
                dropped += 1
            }
        }
        
        return Polyhedron(vertices: vertices, faces: faces, name: "unknown polyhedron")
    }
}

