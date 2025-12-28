//
// PolyhedronismeSwift
// BundleProvider.swift
//
// Protocol for bundle operations to enable testability
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol BundleProvider: Sendable {
    func url(forResource name: String, withExtension ext: String) -> URL?
    func url(forResource name: String, withExtension ext: String, subdirectory: String?) -> URL?
    func readContents(of url: URL) throws -> String
}

// Default implementation using real Bundle
internal struct DefaultBundleProvider: BundleProvider {
    private let bundles: [Bundle]
    
    init(bundles: [Bundle] = [Bundle.main, Bundle.module, Bundle(for: MetalContext.self)]) {
        self.bundles = bundles
    }
    
    func url(forResource name: String, withExtension ext: String) -> URL? {
        for bundle in bundles {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
    
    func url(forResource name: String, withExtension ext: String, subdirectory: String?) -> URL? {
        for bundle in bundles {
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }
    
    func readContents(of url: URL) throws -> String {
        return try String(contentsOf: url)
    }
}

