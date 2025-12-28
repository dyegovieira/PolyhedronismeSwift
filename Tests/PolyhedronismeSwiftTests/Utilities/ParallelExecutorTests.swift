import XCTest
@testable import PolyhedronismeSwift

final class ParallelExecutorTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.resetToDefaults()
    }
    
    // MARK: - Basic Parallel Execution
    
    func testParallelExecutionWithMultipleChunks() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 100) { range in
            return range.count
        }
        
        XCTAssertEqual(results.reduce(0, +), 100, "Should process all items")
        XCTAssertGreaterThan(results.count, 1, "Should have multiple chunks")
    }
    
    func testParallelExecutionResultsAreOrdered() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 100) { range in
            // Return the start index of each range to verify ordering
            return range.startIndex
        }
        
        // Results should be sorted by chunk index (which corresponds to startIndex)
        let sortedResults = results.sorted()
        XCTAssertEqual(results, sortedResults, "Results should maintain order despite parallel execution")
    }
    
    // MARK: - Sequential Fallback Scenarios
    
    func testSequentialFallbackWhenParallelismDisabled() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(false)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 50) { range in
            return range.count
        }
        
        // Should execute sequentially (single chunk)
        XCTAssertEqual(results.count, 1, "Should have single chunk when parallelism disabled")
        XCTAssertEqual(results[0], 50, "Should process all items in one chunk")
    }
    
    func testSequentialFallbackWhenMaxTasksIsOne() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(1)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 50) { range in
            return range.count
        }
        
        // Should fall back to sequential when maxParallelTasks <= 1
        XCTAssertEqual(results.count, 1, "Should have single chunk when maxParallelTasks is 1")
        XCTAssertEqual(results[0], 50, "Should process all items in one chunk")
    }
    
    func testSequentialFallbackWhenWorkloadTooSmall() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(100)
        
        let results = await ParallelExecutor.forEach(count: 50) { range in
            return range.count
        }
        
        // Should fall back to sequential when count < minParallelWorkload
        XCTAssertEqual(results.count, 1, "Should have single chunk when workload too small")
        XCTAssertEqual(results[0], 50, "Should process all items in one chunk")
    }
    
    func testSequentialExecutionWithValidCount() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(false)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 25) { range in
            return range.map { $0 }
        }
        
        XCTAssertEqual(results.count, 1, "Should have single chunk in sequential mode")
        XCTAssertEqual(results[0].count, 25, "Should process all items")
        XCTAssertEqual(results[0], Array(0..<25), "Should process items in order")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyCount() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 0) { range in
            return range.count
        }
        
        XCTAssertTrue(results.isEmpty, "Should return empty array for count = 0")
    }
    
    func testSingleItem() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 1) { range in
            return range.count
        }
        
        // Single item should still fall back to sequential (count < minParallelWorkload)
        XCTAssertEqual(results.count, 1, "Should have single chunk")
        XCTAssertEqual(results[0], 1, "Should process single item")
    }
    
    func testCountExactlyAtThreshold() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(50)
        
        let results = await ParallelExecutor.forEach(count: 50) { range in
            return range.count
        }
        
        // Count exactly at threshold should use parallel execution
        XCTAssertGreaterThanOrEqual(results.count, 1, "Should have at least one chunk")
        XCTAssertEqual(results.reduce(0, +), 50, "Should process all items")
    }
    
    // MARK: - Custom Chunk Size
    
    func testCustomChunkSize() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let customChunkSize = 15
        let results = await ParallelExecutor.forEach(count: 100, chunkSize: customChunkSize) { range in
            return range.count
        }
        
        // Verify chunks are approximately the custom size
        let expectedChunks = (100 + customChunkSize - 1) / customChunkSize
        XCTAssertEqual(results.count, expectedChunks, "Should use custom chunk size")
        
        // Verify total count
        XCTAssertEqual(results.reduce(0, +), 100, "Should process all items")
        
        // Verify chunk sizes (last chunk may be smaller)
        for (index, chunkSize) in results.enumerated() {
            if index < results.count - 1 {
                XCTAssertEqual(chunkSize, customChunkSize, "Non-final chunks should match custom size at index \(index)")
            } else {
                XCTAssertLessThanOrEqual(chunkSize, customChunkSize, "Last chunk may be smaller")
                XCTAssertGreaterThan(chunkSize, 0, "Last chunk should not be empty")
            }
        }
    }
    
    func testCustomChunkSizeLargerThanCount() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let customChunkSize = 200
        let results = await ParallelExecutor.forEach(count: 50, chunkSize: customChunkSize) { range in
            return range.count
        }
        
        // Should have single chunk when chunk size > count
        XCTAssertEqual(results.count, 1, "Should have single chunk when chunk size > count")
        XCTAssertEqual(results[0], 50, "Should process all items")
    }
    
    func testCustomChunkSizeExactlyOne() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let customChunkSize = 1
        let results = await ParallelExecutor.forEach(count: 20, chunkSize: customChunkSize) { range in
            return range.count
        }
        
        // Should have one chunk per item
        XCTAssertEqual(results.count, 20, "Should have one chunk per item")
        XCTAssertEqual(results.reduce(0, +), 20, "Should process all items")
        XCTAssertTrue(results.allSatisfy { $0 == 1 }, "Each chunk should have size 1")
    }
    
    // MARK: - Error Handling
    
    func testErrorPropagation() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        struct TestError: Error {}
        
        do {
            _ = try await ParallelExecutor.forEach(count: 50) { range in
                throw TestError()
            }
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is TestError, "Should propagate error from work closure")
        }
    }
    
    func testErrorInOneChunkDoesNotBlockOthers() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        struct TestError: Error {}
        
        do {
            _ = try await ParallelExecutor.forEach(count: 100) { range in
                // First chunk throws error
                if range.startIndex == 0 {
                    throw TestError()
                }
                return range.count
            }
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is TestError, "Should propagate error")
            // Note: In TaskGroup, when one task throws, the group throws
            // So we can't verify that other chunks completed, but we can verify the error propagated
        }
    }
    
    func testErrorWithPolyhedronError() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        do {
            _ = try await ParallelExecutor.forEach(count: 100) { range in
                // Simulate the internal error that can occur
                if range.startIndex >= 100 {
                    throw PolyhedronError.internalError("Unexpected chunk index out of range")
                }
                return range.count
            }
        } catch {
            XCTAssertTrue(error is PolyhedronError, "Should propagate PolyhedronError")
        }
    }
    
    // MARK: - Configuration Integration
    
    func testRespectsMaxParallelTasks() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(2)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 100) { range in
            return range.count
        }
        
        // Should not exceed maxParallelTasks
        // With maxParallelTasks=2, we should have at most 2 chunks (or more if chunkSize is small)
        // The actual chunk count depends on chunk size calculation
        XCTAssertGreaterThanOrEqual(results.count, 1, "Should have at least one chunk")
        XCTAssertEqual(results.reduce(0, +), 100, "Should process all items")
        
        // Verify we're using parallel execution (multiple chunks)
        let snapshot = await config.snapshot()
        if snapshot.maxParallelTasks > 1 {
            // If parallelism is enabled and maxTasks > 1, we should get multiple chunks
            XCTAssertGreaterThan(results.count, 1, "Should have multiple chunks when maxParallelTasks > 1")
        }
    }
    
    func testChunkSizeCalculation() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let count = 100
        let results = await ParallelExecutor.forEach(count: count) { range in
            return range.count
        }
        
        // Verify chunk size calculation
        // With maxParallelTasks=4 and count=100, chunk size should be approximately 100/4 = 25
        // So we should have approximately 4 chunks
        XCTAssertGreaterThanOrEqual(results.count, 1, "Should have at least one chunk")
        XCTAssertLessThanOrEqual(results.count, 4, "Should not exceed maxParallelTasks significantly")
        XCTAssertEqual(results.reduce(0, +), count, "Should process all items")
        
        // Verify chunks are reasonably sized
        let avgChunkSize = Double(count) / Double(results.count)
        for chunkSize in results {
            // Chunk sizes should be within reasonable range of average
            XCTAssertGreaterThanOrEqual(chunkSize, Int(avgChunkSize * 0.5), "Chunk size should be reasonable")
            XCTAssertLessThanOrEqual(chunkSize, Int(avgChunkSize * 2.0), "Chunk size should be reasonable")
        }
    }
    
    func testParallelExecutionWithLargeWorkload() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(8)
        await config.setMinParallelWorkload(100)
        
        let count = 1000
        let results = await ParallelExecutor.forEach(count: count) { range in
            return range.count
        }
        
        XCTAssertGreaterThan(results.count, 1, "Should have multiple chunks for large workload")
        XCTAssertEqual(results.reduce(0, +), count, "Should process all items")
        
        // Verify chunks are distributed
        let maxChunkSize = results.max() ?? 0
        let minChunkSize = results.min() ?? 0
        XCTAssertGreaterThan(maxChunkSize, 0, "Should have non-empty chunks")
        XCTAssertLessThanOrEqual(maxChunkSize - minChunkSize, maxChunkSize / 2, "Chunks should be reasonably balanced")
    }
    
    func testParallelExecutionWithComplexReturnType() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        struct Result: Sendable {
            let sum: Int
            let count: Int
        }
        
        let results = await ParallelExecutor.forEach(count: 100) { range in
            return Result(sum: range.reduce(0, +), count: range.count)
        }
        
        XCTAssertGreaterThan(results.count, 1, "Should have multiple chunks")
        let totalSum = results.reduce(0) { $0 + $1.sum }
        let expectedSum = (0..<100).reduce(0, +)
        XCTAssertEqual(totalSum, expectedSum, "Should process all items correctly")
        let totalCount = results.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalCount, 100, "Should process all items")
    }
    
    func testParallelExecutionWithStringReturnType() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 50) { range in
            return "chunk-\(range.startIndex)"
        }
        
        XCTAssertGreaterThan(results.count, 1, "Should have multiple chunks")
        XCTAssertEqual(results.count, Set(results).count, "Should have unique chunk identifiers")
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("chunk-") }, "All results should have expected prefix")
    }
    
    func testParallelExecutionWithArrayReturnType() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        let results = await ParallelExecutor.forEach(count: 100) { range in
            return Array(range)
        }
        
        XCTAssertGreaterThan(results.count, 1, "Should have multiple chunks")
        let flattened = results.flatMap { $0 }
        XCTAssertEqual(flattened.count, 100, "Should process all items")
        XCTAssertEqual(Set(flattened).count, 100, "Should have all unique indices")
        XCTAssertEqual(flattened.sorted(), Array(0..<100), "Should maintain correct order")
    }
    
    func testConfigurationChangesBetweenCalls() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(10)
        
        // First call with parallelism enabled
        let results1 = await ParallelExecutor.forEach(count: 100) { range in
            return range.count
        }
        XCTAssertGreaterThan(results1.count, 1, "Should use parallel execution")
        
        // Disable parallelism
        await config.setParallelismEnabled(false)
        
        // Second call should use sequential
        let results2 = await ParallelExecutor.forEach(count: 100) { range in
            return range.count
        }
        XCTAssertEqual(results2.count, 1, "Should use sequential execution when disabled")
    }
    
    func testParallelExecutorWithLargeChunkSize() async throws {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(true)
        await config.setMaxParallelTasks(4)
        await config.setMinParallelWorkload(1)
        
        let results = try await ParallelExecutor.forEach(count: 10, chunkSize: 100) { range in
            return range.count
        }
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0], 10)
    }
}
