//
// PolyhedronismeSwift
// ParallelExecutor.swift
//
// Parallel executor utility for concurrent task execution
//
// Created by Dyego Vieira de Paula on 2025-11-17
// Built with AI-assisted development via Cursor IDE
//
import Foundation

enum ParallelExecutor {
    static func forEach<T: Sendable>(
        count: Int,
        chunkSize: Int? = nil,
        _ work: @escaping @Sendable (Range<Int>) async throws -> T
    ) async rethrows -> [T] {
        let configuration = await PolyhedronismeSwiftConfiguration.shared.snapshot()
        
        guard configuration.parallelismEnabled,
              configuration.maxParallelTasks > 1,
              count >= configuration.minParallelWorkload else {
            if count > 0 {
                return [try await work(0..<count)]
            }
            return []
        }
        
        let tasks = max(1, min(configuration.maxParallelTasks, count))
        let size = chunkSize ?? max(1, (count + tasks - 1) / tasks)
        let chunkCount = max(1, (count + size - 1) / size)
        
        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for index in 0..<chunkCount {
                group.addTask {
                    let start = index * size
                    guard start < count else {
                        throw PolyhedronError.internalError("Unexpected chunk index out of range")
                    }
                    let end = min(count, start + size)
                    let result = try await work(start..<end)
                    return (index, result)
                }
            }
            
            var results: [(Int, T)] = []
            results.reserveCapacity(chunkCount)
            for try await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}

