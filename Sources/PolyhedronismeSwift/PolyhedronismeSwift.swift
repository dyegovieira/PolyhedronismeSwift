//
// PolyhedronismeSwift
// PolyhedronismeSwift.swift
//
// Main entry point for generating polyhedra using Conway operators
//
// Created by Dyego Vieira de Paula on 2025-11-03
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public struct PolyhedronismeSwiftGenerator: PolyhedronismeSwiftProtocol {
    private let generator: PolyhedronGeneratorProtocol
    
    public init() {
        let baseRegistry = StandardBaseRegistry.makeDefault()
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        
        // Initialize Metal infrastructure
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        // Initialize factory with dependencies
        let operatorFactory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        self.generator = DefaultPolyhedronGenerator(
            baseRegistry: baseRegistry,
            operatorRegistry: operatorRegistry,
            operatorFactory: operatorFactory
        )
    }
    
    public func generate(recipe: String) async throws -> Polyhedron {
        let model = try await generator.generate(notation: recipe)
        return Polyhedron(
            vertices: model.vertices,
            faces: model.faces,
            name: model.name,
            faceClasses: model.faceClasses,
            recipe: recipe
        )
    }
    
    public func stream(recipe: String) -> AsyncThrowingStream<GenerationEvent, Error> {
        generator.stream(notation: recipe)
    }
}

