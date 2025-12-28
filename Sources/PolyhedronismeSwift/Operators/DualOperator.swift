//
// PolyhedronismeSwift
// DualOperator.swift
//
// Dual operator implementation for polyhedral transformations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DualOperator: PolyhedronOperator {
    public let identifier: String = "d"
    
    private let edgeCalculator: EdgeCalculator
    private let faceCalculator: FaceCalculator
    
    public init(
        edgeCalculator: EdgeCalculator = DefaultEdgeCalculator(),
        faceCalculator: FaceCalculator = DefaultFaceCalculator()
    ) {
        self.edgeCalculator = edgeCalculator
        self.faceCalculator = faceCalculator
    }
    
    public func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        var flag = PolyFlag()
        
        var faceMap: [[Int: Int]] = Array(repeating: [:], count: polyhedron.vertices.count)
        
        let faceCount = polyhedron.faces.count
        let configuration = await PolyhedronismeSwiftConfiguration.shared.snapshot()
        let chunkBase = max(1, configuration.maxParallelTasks * 2)
        let dualChunkSize = max(configuration.minParallelWorkload, max(1, faceCount / chunkBase))
        if faceCount > 0 {
            let mapAssignments = await ParallelExecutor.forEach(count: faceCount, chunkSize: dualChunkSize) { range in
                var local: [(Int, [(Int, Int, Int)])] = []
                local.reserveCapacity(range.count)
                for idx in range {
                    var entries: [(Int, Int, Int)] = []
                    let face = polyhedron.faces[idx]
                    guard !face.isEmpty else { continue }
                    var v1 = face[face.count - 1]
                    for v2 in face {
                        entries.append((v1, v2, idx))
                        v1 = v2
                    }
                    local.append((idx, entries))
                }
                return local
            }
            
            for chunk in mapAssignments {
                for entry in chunk {
                    let (_, entries) = entry
                    for triple in entries {
                        let (fromVertex, toVertex, faceIndex) = triple
                        faceMap[fromVertex][toVertex] = faceIndex
                    }
                }
            }
        }
        
        var cacheablePolyhedron = polyhedron
        let centers = await cacheablePolyhedron.cachedCenters(using: faceCalculator)
        for i in 0..<polyhedron.faces.count {
            flag.newV("\(i)", centers[i])
        }
        
        let faceMapSnapshot = faceMap
        let pendingInstructions = await ParallelExecutor.forEach(count: faceCount, chunkSize: dualChunkSize) { range in
            var local: [DualFlagInstruction] = []
            local.reserveCapacity(range.count)
            for idx in range {
                local.append(
                    DualFlagInstruction.build(
                        faceIndex: idx,
                        face: polyhedron.faces[idx],
                        faceMap: faceMapSnapshot
                    )
                )
            }
            return local
        }
        
        var undefinedFlagsCount = 0
        var totalFlagsCount = 0
        for chunk in pendingInstructions {
            for instruction in chunk {
                undefinedFlagsCount += instruction.undefinedCount
                totalFlagsCount += instruction.totalCount
                for command in instruction.commands {
                    let fromFace = command.fromFaceIndex.map { "\($0)" } ?? "undefined"
                    flag.newFlag("v\(command.vertexIndex)", fromFace, "\(command.toFaceIndex)")
                }
            }
        }
        
        let faceNames = flag.faceNamesInOrder()
        let dpoly = flag.topoly()
        
        var sortF = SparseArray<[Int]>(capacity: polyhedron.vertices.count)
        var facesWithK = 0
        var fallbackFaces = 0
        
        let zippedCount = min(faceNames.count, dpoly.faces.count)
        var unmatchedFaces: [[Int]] = []
        
        for idx in 0..<zippedCount {
            let name = faceNames[idx]
            let face = dpoly.faces[idx]
            guard face.count >= 3 else { continue }
            if let vertexIndex = parseVertexIndex(from: name) {
                sortF[vertexIndex] = face
                facesWithK += 1
            } else {
                unmatchedFaces.append(face)
            }
        }
        if zippedCount < dpoly.faces.count {
            unmatchedFaces.append(contentsOf: dpoly.faces[zippedCount..<dpoly.faces.count])
        }
        
        if !unmatchedFaces.isEmpty {
            for face in unmatchedFaces {
                guard face.count >= 3 else { continue }
                if let fallback = GeometryUtils.intersect(
                    polyhedron.faces[face[0]],
                    polyhedron.faces[face[1]],
                    polyhedron.faces[face[2]]
                ), fallback >= 0 {
                    sortF[fallback] = face
                    facesWithK += 1
                    fallbackFaces += 1
                }
            }
        }
        
        let finalFaces = sortF.compacted(size: polyhedron.vertices.count, defaultValue: [])
        
        var newName = polyhedron.name
        if let firstChar = newName.first, firstChar != "d" {
            newName = "d\(newName)"
        } else if newName.count > 1 {
            let start = newName.index(newName.startIndex, offsetBy: 1)
            newName = String(newName[start...])
        }
        
        let resultModel = PolyhedronModel(
            vertices: dpoly.vertices,
            faces: finalFaces,
            name: newName,
            faceClasses: []
        )
        
        return resultModel
    }
}

private struct DualFlagInstruction {
    struct Command {
        let vertexIndex: Int
        let fromFaceIndex: Int?
        let toFaceIndex: Int
    }
    
    var commands: [Command] = []
    var undefinedCount: Int = 0
    var totalCount: Int = 0
    
    static func build(
        faceIndex: Int,
        face: Face,
        faceMap: [[Int: Int]]
    ) -> DualFlagInstruction {
        var instruction = DualFlagInstruction()
        guard !face.isEmpty else { return instruction }
        var v1 = face[face.count - 1]
        for v2 in face {
            instruction.totalCount += 1
            let nextFaceIdx = faceMap[v2][v1]
            if nextFaceIdx == nil {
                instruction.undefinedCount += 1
            }
            instruction.commands.append(
                Command(
                    vertexIndex: v1,
                    fromFaceIndex: nextFaceIdx,
                    toFaceIndex: faceIndex
                )
            )
            v1 = v2
        }
        return instruction
    }
}

private func parseVertexIndex(from faceName: String) -> Int? {
    guard let first = faceName.first, first == "v" else {
        return Int(faceName)
    }
    return Int(faceName.dropFirst())
}

