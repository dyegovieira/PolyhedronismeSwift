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

public struct PolyhedronismeSwiftGenerator: PolyhedronismeSwiftProtocol, Sendable {
    private let generator: PolyhedronGeneratorProtocol
    private let parallelismConfiguration: ParallelismConfiguration?
    
    public init(parallelismConfiguration: ParallelismConfiguration? = nil) {
        let baseRegistry = StandardBaseRegistry.makeDefault()
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        
        let metalExecutor = MetalExecutor()
        
        // Initialize factory with dependencies
        let operatorFactory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalExecutor: metalExecutor
        )
        
        self.generator = DefaultPolyhedronGenerator(
            baseRegistry: baseRegistry,
            operatorRegistry: operatorRegistry,
            operatorFactory: operatorFactory
        )
        self.parallelismConfiguration = parallelismConfiguration
    }
    
    public func generate(recipe: String) async throws -> Polyhedron {
        let model: PolyhedronModel
        if let parallelismConfiguration {
            model = try await ParallelismRequestContext.$configuration.withValue(parallelismConfiguration) {
                try await generator.generate(notation: recipe)
            }
        } else {
            model = try await generator.generate(notation: recipe)
        }
        return Polyhedron(
            vertices: model.vertices,
            faces: model.faces,
            name: model.name,
            faceClasses: model.faceClasses,
            recipe: recipe
        )
    }
    
    public func stream(recipe: String) -> AsyncThrowingStream<GenerationEvent, Error> {
        if let parallelismConfiguration {
            return ParallelismRequestContext.$configuration.withValue(parallelismConfiguration) {
                generator.stream(notation: recipe)
            }
        }
        return generator.stream(notation: recipe)
    }
}
