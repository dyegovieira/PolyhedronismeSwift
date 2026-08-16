//
// PolyhedronismeSwift
// PolyhedronismeSwiftConfiguration.swift
//
// Configuration utility for PolyhedronismeSwift library settings
//
// Created by Dyego Vieira de Paula on 2025-11-22
// Built with AI-assisted development via Cursor IDE
//
import Foundation

public struct ParallelismConfiguration: Sendable, Equatable {
    public let parallelismEnabled: Bool
    public let maxParallelTasks: Int
    public let minParallelWorkload: Int

    public init(
        parallelismEnabled: Bool,
        maxParallelTasks: Int,
        minParallelWorkload: Int
    ) {
        self.parallelismEnabled = parallelismEnabled
        self.maxParallelTasks = max(1, maxParallelTasks)
        self.minParallelWorkload = max(1, minParallelWorkload)
    }
}

enum ParallelismRequestContext {
    @TaskLocal static var configuration: ParallelismConfiguration?
}

public actor PolyhedronismeSwiftConfiguration {
    public typealias Snapshot = ParallelismConfiguration
    
    public static let shared = PolyhedronismeSwiftConfiguration()
    
    private var _parallelismEnabled: Bool = true
    private var _maxParallelTasks: Int = ProcessInfo.processInfo.activeProcessorCount
    private var _minParallelWorkload: Int = 256
    
    public var parallelismEnabled: Bool {
        get { _parallelismEnabled }
        set { _parallelismEnabled = newValue }
    }
    
    public var maxParallelTasks: Int {
        get { _maxParallelTasks }
        set { _maxParallelTasks = max(1, newValue) }
    }
    
    public var minParallelWorkload: Int {
        get { _minParallelWorkload }
        set { _minParallelWorkload = max(1, newValue) }
    }
    
    public func snapshot() -> Snapshot {
        ParallelismConfiguration(
            parallelismEnabled: _parallelismEnabled,
            maxParallelTasks: _maxParallelTasks,
            minParallelWorkload: _minParallelWorkload
        )
    }
    
    public func setParallelismEnabled(_ value: Bool) {
        _parallelismEnabled = value
    }
    
    public func setMaxParallelTasks(_ value: Int) {
        _maxParallelTasks = max(1, value)
    }
    
    public func setMinParallelWorkload(_ value: Int) {
        _minParallelWorkload = max(1, value)
    }
    
    public func resetToDefaults() {
        _parallelismEnabled = true
        _maxParallelTasks = ProcessInfo.processInfo.activeProcessorCount
        _minParallelWorkload = 256
    }
}
