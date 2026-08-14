//
// PolyhedronismeSwift
// MetalCommandBufferWrapper.swift
//
// Metal CommandBuffer wrapper for GPU resource abstraction
//
// Created by Dyego Vieira de Paula on 2025-11-23
// Built with AI-assisted development via Cursor IDE
//
#if canImport(Metal)
@preconcurrency import Metal
#endif
import Foundation

#if canImport(Metal)
internal final class MetalCommandBufferWrapper: MetalCommandBuffer, Sendable {
    private let buffer: MTLCommandBuffer
    
    init(buffer: MTLCommandBuffer) {
        self.buffer = buffer
    }
    
    func makeComputeCommandEncoder() -> MetalComputeCommandEncoder? {
        guard let encoder = buffer.makeComputeCommandEncoder() else { return nil }
        return MetalComputeCommandEncoderWrapper(encoder: encoder)
    }
    
    func commit() {
        buffer.commit()
    }
    
    func completed() async throws {
        final class ResumeState: @unchecked Sendable {
            private let lock = NSLock()
            private var resumed = false
            private var continuation: CheckedContinuation<Void, Error>?
            
            func tryResume(throwing error: Error) -> Bool {
                lock.lock()
                defer { lock.unlock() }
                
                guard !resumed, let continuation = continuation else {
                    return false
                }
                resumed = true
                self.continuation = nil
                continuation.resume(throwing: error)
                return true
            }
            
            func tryResume() -> Bool {
                lock.lock()
                defer { lock.unlock() }
                
                guard !resumed, let continuation = continuation else {
                    return false
                }
                resumed = true
                self.continuation = nil
                continuation.resume()
                return true
            }
            
            func setContinuation(_ continuation: CheckedContinuation<Void, Error>) {
                lock.lock()
                defer { lock.unlock() }
                self.continuation = continuation
            }
        }
        
        let state = ResumeState()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Completion handler task
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    state.setContinuation(continuation)
                    
                    self.buffer.addCompletedHandler { commandBuffer in
                        if let error = commandBuffer.error {
                            let nsError = error as NSError
                            _ = state.tryResume(throwing: MetalError.commandBufferFailed(nsError.localizedDescription))
                        } else {
                            _ = state.tryResume()
                        }
                    }
                }
            }
            
            // Timeout task - 10 seconds
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                if !state.tryResume(throwing: MetalError.commandBufferFailed("Command buffer execution timed out after 10 seconds")) {
                    throw CancellationError()
                }
            }
            
            // Wait for whichever completes first
            try await group.next()
            group.cancelAll()
        }
    }
}
#endif

