//
// PolyhedronismeSwift
// ComputePipelineFactory.swift
//
// ComputePipelineFactory service implementation for polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal actor ComputePipelineFactory {
    private let metalConfig: MetalConfiguration
    private let bundleProvider: BundleProvider
    private var pipelines: [String: MetalComputePipelineState] = [:]
    
    init(metalConfig: MetalConfiguration, bundleProvider: BundleProvider? = nil) {
        self.metalConfig = metalConfig
        self.bundleProvider = bundleProvider ?? DefaultBundleProvider()
    }
    
    func pipeline(for functionName: String) throws -> MetalComputePipelineState {
        if let existing = pipelines[functionName] {
            return existing
        }
        
        guard let device = metalConfig.device else {
            throw MetalError.deviceNotFound
        }
        
        // 1. Try default library (App Bundle)
        if let library = device.makeDefaultLibrary(),
           let function = library.makeFunction(name: functionName) {
            let pipeline = try device.makeComputePipelineState(function: function)
            pipelines[functionName] = pipeline
            return pipeline
        }
        
        // Try to load from known Metal files
        let metalFiles = ["GeometryKernels", "KisOperatorKernels", "AmboOperatorKernels", "ReflectOperatorKernels"]
        let subdirectories: [String?] = [nil, "Metal", "PolyhedronismeSwift_PolyhedronismeSwift.bundle/Metal"]
        
        for fileName in metalFiles {
            for subdirectory in subdirectories {
                if let url = bundleProvider.url(forResource: fileName, withExtension: "metal", subdirectory: subdirectory) {
                    if let source = try? bundleProvider.readContents(of: url) {
                        do {
                            let library = try device.makeLibrary(source: source, options: nil)
                            if let function = library.makeFunction(name: functionName) {
                                let pipeline = try device.makeComputePipelineState(function: function)
                                pipelines[functionName] = pipeline
                                return pipeline
                            }
                        } catch {
                            print("[ComputePipelineFactory] Error compiling \(fileName): \(error)")
                            // Continue to next file/bundle
                        }
                    }
                }
            }
        }
        
        print("[ComputePipelineFactory] Function '\(functionName)' not found in any Metal file")
        throw MetalError.functionNotFound(functionName)
    }
}

