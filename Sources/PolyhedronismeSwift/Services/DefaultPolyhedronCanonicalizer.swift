//
// PolyhedronismeSwift
// DefaultPolyhedronCanonicalizer.swift
//
// Default polyhedron canonicalizer service implementation for geometric normalization
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultPolyhedronCanonicalizer: PolyhedronCanonicalizer {
    private let dualOperator: DualOperator
    private let pipelineActor: CanonicalizationPipelineActor
    
    public init(
        dualOperator: DualOperator = DualOperator(),
        enableMetal: Bool = true
    ) {
        self.dualOperator = dualOperator
        self.pipelineActor = CanonicalizationPipelineActor(enableMetal: enableMetal)
    }
    
    public func adjust(_ polyhedron: Polyhedron, iterations: Int) async -> Polyhedron {
        let nIter = iterations
        var dpolyModel: PolyhedronModel
        do {
            dpolyModel = try await dualOperator.apply(to: PolyhedronModel(polyhedron))
        } catch {
            return polyhedron
        }
        var dpoly = Polyhedron(dpolyModel, recipe: polyhedron.recipe)
        
        var polyMut = Polyhedron(vertices: polyhedron.vertices, faces: polyhedron.faces, name: polyhedron.name, faceClasses: polyhedron.faceClasses, recipe: polyhedron.recipe)
        for _ in 0..<nIter {
            let dStage = await pipelineActor.reciprocalC(vertices: ContiguousArray(polyMut.vertices))
            logTelemetry(dStage.telemetry, polyName: polyhedron.name)
            dpoly.vertices = dStage.asArray()
            
            let polyStage = await pipelineActor.reciprocalC(vertices: ContiguousArray(dpoly.vertices))
            logTelemetry(polyStage.telemetry, polyName: polyhedron.name)
            polyMut.vertices = polyStage.asArray()
        }
        
        return Polyhedron(vertices: polyMut.vertices, faces: polyMut.faces, name: polyMut.name, faceClasses: polyMut.faceClasses, recipe: polyMut.recipe)
    }
    
    public func canonicalize(_ polyhedron: Polyhedron, iterations: Int) async -> Polyhedron {
        let nIter = iterations
        var dpolyModel: PolyhedronModel
        do {
            dpolyModel = try await dualOperator.apply(to: PolyhedronModel(polyhedron))
        } catch {
            return polyhedron
        }
        var dpoly = Polyhedron(dpolyModel, recipe: polyhedron.recipe)
        
        var polyMut = Polyhedron(vertices: polyhedron.vertices, faces: polyhedron.faces, name: polyhedron.name, faceClasses: polyhedron.faceClasses, recipe: polyhedron.recipe)
        for _ in 0..<nIter {
            let dStage = await pipelineActor.reciprocalN(vertices: ContiguousArray(polyMut.vertices), faces: polyMut.faces)
            logTelemetry(dStage.telemetry, polyName: polyhedron.name)
            dpoly.vertices = dStage.asArray()
            
            let polyStage = await pipelineActor.reciprocalN(vertices: ContiguousArray(dpoly.vertices), faces: dpoly.faces)
            logTelemetry(polyStage.telemetry, polyName: polyhedron.name)
            polyMut.vertices = polyStage.asArray()
        }
        
        return Polyhedron(vertices: polyMut.vertices, faces: polyMut.faces, name: polyMut.name, faceClasses: polyMut.faceClasses, recipe: polyMut.recipe)
    }
    
    private func logTelemetry(_ telemetry: CanonicalizationTelemetry, polyName: String) {
        // Telemetry logging could be enabled here if needed
        // print("Stage: \(telemetry.stage), Mode: \(telemetry.usedGPU ? "GPU" : "CPU"), Time: \(telemetry.executionTime)")
    }
}

