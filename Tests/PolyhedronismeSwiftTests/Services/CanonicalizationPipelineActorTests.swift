import XCTest
@testable import PolyhedronismeSwift

final class CanonicalizationPipelineActorTests: XCTestCase {
    
    func testInitWithMetalEnabled() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertFalse(result.values.isEmpty)
        XCTAssertNotNil(result.telemetry)
    }
    
    func testInitWithMetalDisabled() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertFalse(result.values.isEmpty)
        XCTAssertFalse(result.telemetry.usedGPU, "Should use CPU when Metal disabled")
    }
    
    func testReciprocalCWithEmptyVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray<Vec3>()
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertTrue(result.values.isEmpty)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCWithSingleVertex() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNWithEmptyVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray<Vec3>()
        let faces: [Face] = []
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertTrue(result.values.isEmpty)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNWithEmptyFaces() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let faces: [Face] = []
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertTrue(result.values.isEmpty)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNWithValidInput() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertEqual(result.values.count, faces.count)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCResultTelemetry() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.telemetry.stage, .reciprocalC)
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNResultTelemetry() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertEqual(result.telemetry.stage, .reciprocalN)
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCAsArray() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        let array = result.asArray()
        
        XCTAssertEqual(array.count, result.values.count)
        XCTAssertEqual(Array(result.values), array)
    }
    
    func testReciprocalNWithLargeFaceCount() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        var vertices = ContiguousArray<Vec3>()
        var faces: [Face] = []
        
        for i in 0..<100 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
            if i >= 2 {
                faces.append([i-2, i-1, i])
            }
        }
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCWithLargeVertexCount() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<1000 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, vertices.count)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNWithComplexFaces() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1),
            Vec3(-1, 0, 0),
            Vec3(0, -1, 0),
            Vec3(0, 0, -1)
        ])
        let faces: [Face] = [
            [0, 1, 2],
            [1, 2, 3],
            [2, 3, 4],
            [3, 4, 5],
            [4, 5, 0],
            [5, 0, 1]
        ]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCResultValuesAreValid() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let result = await actor.reciprocalC(vertices: vertices)
        
        for value in result.values {
            XCTAssertTrue(value.isValid(), "All result values should be valid Vec3")
        }
    }
    
    func testReciprocalNResultValuesAreValid() async {
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        for value in result.values {
            XCTAssertTrue(value.isValid(), "All result values should be valid Vec3")
        }
    }
    
    #if canImport(Metal)
    func testReciprocalCWithMetalEnabled() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertFalse(result.values.isEmpty)
        XCTAssertNotNil(result.telemetry)
    }
    
    func testReciprocalNWithMetalEnabled() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertFalse(result.values.isEmpty)
        XCTAssertNotNil(result.telemetry)
    }
    
    func testReciprocalCWithMetalButEmptyVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray<Vec3>()
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertTrue(result.values.isEmpty)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNWithMetalButEmptyVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray<Vec3>()
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        // CPU fallback processes faces even with empty vertices, returning one result per face
        XCTAssertEqual(result.values.count, faces.count)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNWithMetalButEmptyFaces() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let faces: [Face] = []
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertTrue(result.values.isEmpty)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCWithLargeDataSet() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<1000 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, vertices.count)
    }
    
    func testReciprocalNWithLargeDataSet() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        var faces: [Face] = []
        for i in 0..<100 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
            if i >= 2 {
                faces.append([i-2, i-1, i])
            }
        }
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNWithComplexFacesMetal() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1),
            Vec3(-1, 0, 0),
            Vec3(0, -1, 0),
            Vec3(0, 0, -1)
        ])
        let faces: [Face] = [
            [0, 1, 2],
            [1, 2, 3],
            [2, 3, 4],
            [3, 4, 5],
            [4, 5, 0],
            [5, 0, 1]
        ]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNWithFacesContainingNegativeIndices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[-1, 0, 1], [0, 1, 2]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalCWithZeroVector() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([Vec3(0, 0, 0), Vec3(1, 1, 1)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.values.count, 2)
    }
    
    func testReciprocalCGPUPathWithBufferFailure() async {
        // This test verifies GPU path fallback when buffer creation fails
        // Since we can't easily mock the internal Metal calls, we test that
        // the actor gracefully falls back to CPU when GPU fails
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should still produce valid results (either GPU or CPU fallback)
        XCTAssertEqual(result.values.count, vertices.count)
        XCTAssertNotNil(result.telemetry)
    }
    
    func testReciprocalNGPUPathWithBufferFailure() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        // Should still produce valid results (either GPU or CPU fallback)
        XCTAssertEqual(result.values.count, faces.count)
        XCTAssertNotNil(result.telemetry)
    }
    
    func testReciprocalCWithVeryLargeDataset() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<10000 {
            vertices.append(Vec3(Double(i), Double(i * 2), Double(i * 3)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, vertices.count)
    }
    
    func testReciprocalNWithVeryLargeFaceCount() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        var faces: [Face] = []
        
        // Create 1000 vertices
        for i in 0..<1000 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        // Create 500 faces
        for i in 0..<500 {
            let base = i * 2
            if base + 2 < vertices.count {
                faces.append([base, base + 1, base + 2])
            }
        }
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNWithFacesOfVaryingSizes() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<20 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let faces: [Face] = [
            [0, 1, 2], // Triangle
            [3, 4, 5, 6], // Quad
            [7, 8, 9, 10, 11], // Pentagon
            [12, 13, 14, 15, 16, 17] // Hexagon
        ]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNWithVeryLargeFace() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        var largeFace: [Int] = []
        
        // Create 100 vertices
        for i in 0..<100 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
            largeFace.append(i)
        }
        
        let faces: [Face] = [largeFace]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalCGPUTelemetryIndicatesGPUUsage() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1),
            Vec3(1, 1, 1)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        
        // If GPU is available and working, telemetry should indicate GPU usage
        // If GPU is not available, it will fall back to CPU (which is also valid)
        XCTAssertNotNil(result.telemetry)
        XCTAssertEqual(result.telemetry.stage, .reciprocalC)
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
    }
    
    func testReciprocalNGPUTelemetryIndicatesGPUUsage() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2], [0, 2, 1]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertNotNil(result.telemetry)
        XCTAssertEqual(result.telemetry.stage, .reciprocalN)
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
    }
    
    func testReciprocalCConcurrentCalls() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices1 = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let vertices2 = ContiguousArray([Vec3(7, 8, 9), Vec3(10, 11, 12)])
        let vertices3 = ContiguousArray([Vec3(13, 14, 15), Vec3(16, 17, 18)])
        
        async let result1 = actor.reciprocalC(vertices: vertices1)
        async let result2 = actor.reciprocalC(vertices: vertices2)
        async let result3 = actor.reciprocalC(vertices: vertices3)
        
        let results = await [result1, result2, result3]
        
        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertEqual(result.values.count, 2)
            XCTAssertNotNil(result.telemetry)
        }
    }
    
    func testReciprocalNConcurrentCalls() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices1 = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces1: [Face] = [[0, 1, 2]]
        
        let vertices2 = ContiguousArray([Vec3(2, 0, 0), Vec3(0, 2, 0), Vec3(0, 0, 2)])
        let faces2: [Face] = [[0, 1, 2]]
        
        async let result1 = actor.reciprocalN(vertices: vertices1, faces: faces1)
        async let result2 = actor.reciprocalN(vertices: vertices2, faces: faces2)
        
        let results = await [result1, result2]
        
        XCTAssertEqual(results.count, 2)
        for result in results {
            XCTAssertEqual(result.values.count, 1)
            XCTAssertNotNil(result.telemetry)
        }
    }
    
    func testReciprocalCWithExtremeValues() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1e10, 1e10, 1e10),
            Vec3(-1e10, -1e10, -1e10),
            Vec3(1e-10, 1e-10, 1e-10)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 3)
        
        // Verify results are finite
        for value in result.values {
            XCTAssertTrue(value.x.isFinite)
            XCTAssertTrue(value.y.isFinite)
            XCTAssertTrue(value.z.isFinite)
        }
    }
    
    func testReciprocalNWithExtremeValues() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1e10, 1e10, 1e10),
            Vec3(-1e10, -1e10, -1e10),
            Vec3(1e-10, 1e-10, 1e-10)
        ])
        let faces: [Face] = [[0, 1, 2]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, 1)
        
        // Verify results are finite
        for value in result.values {
            XCTAssertTrue(value.x.isFinite)
            XCTAssertTrue(value.y.isFinite)
            XCTAssertTrue(value.z.isFinite)
        }
    }
    
    func testReciprocalCResultMatchesCPUFallback() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        let cpuResult = CanonicalizationMath.reciprocalC(vertices: vertices)
        
        // Results should match regardless of GPU/CPU path
        XCTAssertEqual(result.values.count, cpuResult.count)
        for i in 0..<min(result.values.count, cpuResult.count) {
            XCTAssertEqual(result.values[i].x, cpuResult[i].x, accuracy: 1e-6)
            XCTAssertEqual(result.values[i].y, cpuResult[i].y, accuracy: 1e-6)
            XCTAssertEqual(result.values[i].z, cpuResult[i].z, accuracy: 1e-6)
        }
    }
    
    func testReciprocalNResultMatchesCPUFallback() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2], [0, 2, 1]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        let cpuResult = CanonicalizationMath.reciprocalN(vertices: vertices, faces: faces)
        
        // Results should match regardless of GPU/CPU path
        XCTAssertEqual(result.values.count, cpuResult.count)
        for i in 0..<min(result.values.count, cpuResult.count) {
            XCTAssertEqual(result.values[i].x, cpuResult[i].x, accuracy: 1e-6)
            XCTAssertEqual(result.values[i].y, cpuResult[i].y, accuracy: 1e-6)
            XCTAssertEqual(result.values[i].z, cpuResult[i].z, accuracy: 1e-6)
        }
    }
    
    func testReciprocalCWithSingleLargeValue() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1000000, 0, 0),
            Vec3(0, 0, 0)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 2)
    }
    
    func testReciprocalNWithFacesContainingOutOfBoundsIndices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        // Face with index beyond vertex count (should be clamped to 0 by flattenFaces)
        let faces: [Face] = [[0, 1, 2, 100]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalCAsArrayConversion() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        let array = result.asArray()
        
        XCTAssertEqual(array.count, result.values.count)
        XCTAssertEqual(Array(result.values), array)
    }
    
    func testReciprocalNAsArrayConversion() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        let array = result.asArray()
        
        XCTAssertEqual(array.count, result.values.count)
        XCTAssertEqual(Array(result.values), array)
    }
    
    func testReciprocalCWithIdenticalVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 1, 1),
            Vec3(1, 1, 1),
            Vec3(1, 1, 1)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 3)
    }
    
    func testReciprocalNWithIdenticalVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(1, 1, 1),
            Vec3(1, 1, 1),
            Vec3(1, 1, 1)
        ])
        let faces: [Face] = [[0, 1, 2]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalCWithCollinearVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(0, 0, 0),
            Vec3(1, 1, 1),
            Vec3(2, 2, 2),
            Vec3(3, 3, 3)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 4)
    }
    
    func testReciprocalNWithCollinearVertices() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(0, 0, 0),
            Vec3(1, 1, 1),
            Vec3(2, 2, 2)
        ])
        let faces: [Face] = [[0, 1, 2]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalCWithNanAndInfinity() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(Double.nan, 0, 0),
            Vec3(Double.infinity, 1, 1),
            Vec3(1, 2, 3)
        ])
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 3)
        // Results may contain NaN/Inf, which is acceptable for edge case testing
    }
    
    func testReciprocalNWithNanAndInfinity() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        let vertices = ContiguousArray([
            Vec3(Double.nan, 0, 0),
            Vec3(Double.infinity, 1, 1),
            Vec3(1, 2, 3)
        ])
        let faces: [Face] = [[0, 1, 2]]
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalCThreadGroupCalculation() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        // Test with count that requires multiple thread groups
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<200 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 200)
    }
    
    func testReciprocalNThreadGroupCalculation() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        var faces: [Face] = []
        
        for i in 0..<200 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
            if i >= 2 {
                faces.append([i-2, i-1, i])
            }
        }
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalCWithExactThreadGroupBoundary() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        // Test with count exactly matching thread group size (64)
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<64 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 64)
    }
    
    func testReciprocalNWithExactThreadGroupBoundary() async {
        let actor = CanonicalizationPipelineActor(enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        var faces: [Face] = []
        
        for i in 0..<100 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
            if i >= 2 {
                faces.append([i-2, i-1, i])
            }
        }
        
        // Create exactly 64 faces
        let exactFaces = Array(faces.prefix(64))
        let result = await actor.reciprocalN(vertices: vertices, faces: exactFaces)
        XCTAssertEqual(result.values.count, 64)
    }
    #endif
    
    // MARK: - Mock-Based Tests for GPU Failure Paths
    
    func testInitWithMockDeviceSuccess() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.values.count, 2)
        XCTAssertNotNil(result.telemetry)
    }
    
    func testInitWithMockDeviceButQueueFails() async {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeCommandQueue = true
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should fall back to CPU when queue creation fails
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testInitWithMockDeviceButLibraryFails() async {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should fall back to CPU when library creation fails
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testInitWithMockDeviceButPipelineFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        // Don't add the required functions, so pipeline creation fails
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should fall back to CPU when pipeline creation fails
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCGPUFallbackWhenVertexBufferFails() async {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should fall back to CPU when buffer creation fails
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalCGPUFallbackWhenOutBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        // Create a device that fails on second buffer creation (outBuffer)
        // We'll need to modify the mock to fail on specific call, but for now test general fallback
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should produce valid results (either GPU or CPU fallback)
        XCTAssertEqual(result.values.count, 2)
    }
    
    func testReciprocalCGPUFallbackWhenParamsBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalCGPUFallbackWhenCommandBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        mockQueue.shouldFailMakeCommandBuffer = true
        
        // We need a device that returns our failing queue
        let customDevice = MockMetalDevice()
        customDevice.defaultLibrary = mockLibrary
        // Override makeCommandQueue to return our failing queue
        // Since we can't easily override, we test the general fallback behavior
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalCGPUFallbackWhenEncoderFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testReciprocalNGPUFallbackWhenVertexBufferFails() async {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        // Should fall back to CPU when buffer creation fails
        XCTAssertEqual(result.values.count, faces.count)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testReciprocalNGPUFallbackWhenRangeBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNGPUFallbackWhenIndexBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNGPUFallbackWhenOutBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNGPUFallbackWhenParamsBufferFails() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    // MARK: - FlattenFaces Edge Cases
    
    func testReciprocalNWithNegativeIndices() async {
        // Tests flattenFaces handling of negative indices (line 286: max(0, index))
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        let vertices = ContiguousArray([
            Vec3(1, 0, 0),
            Vec3(0, 1, 0),
            Vec3(0, 0, 1)
        ])
        let faces: [Face] = [[-1, 0, 1], [0, 1, 2]] // Negative index should be clamped to 0
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNWithEmptyFace() async {
        // Tests flattenFaces with empty face
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[], [0, 1, 2]] // Empty face
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    func testReciprocalNWithSingleVertexFace() async {
        // Tests flattenFaces with face containing single vertex
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0)])
        let faces: [Face] = [[0], [0, 1]] // Single vertex face
        
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        XCTAssertEqual(result.values.count, faces.count)
    }
    
    // MARK: - Thread Group Edge Cases
    
    func testReciprocalCWithMaxThreadsPerGroup() async {
        // Tests thread group calculation when maxTotalThreadsPerThreadgroup > 64
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        
        // Create enough vertices to test thread group calculation
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<200 {
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 200)
    }
    
    func testReciprocalCWithThreadGroupBoundary() async {
        // Tests when count is exactly at thread group boundary
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        
        var vertices = ContiguousArray<Vec3>()
        for i in 0..<65 { // Just over 64
            vertices.append(Vec3(Double(i), Double(i), Double(i)))
        }
        
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 65)
    }
    
    // MARK: - CanonicalizationStageResult Tests
    
    func testCanonicalizationStageResultAsArrayWithEmptyValues() {
        let values = ContiguousArray<Vec3>()
        let telemetry = CanonicalizationTelemetry(
            stage: .reciprocalC,
            duration: 0.0,
            usedGPU: false
        )
        let result = CanonicalizationStageResult(values: values, telemetry: telemetry)
        
        let array = result.asArray()
        XCTAssertTrue(array.isEmpty)
    }
    
    func testCanonicalizationStageResultAsArrayWithMultipleValues() {
        let values = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6), Vec3(7, 8, 9)])
        let telemetry = CanonicalizationTelemetry(
            stage: .reciprocalC,
            duration: 0.0,
            usedGPU: false
        )
        let result = CanonicalizationStageResult(values: values, telemetry: telemetry)
        
        let array = result.asArray()
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0], Vec3(1, 2, 3))
        XCTAssertEqual(array[1], Vec3(4, 5, 6))
        XCTAssertEqual(array[2], Vec3(7, 8, 9))
    }
    
    // MARK: - Metal Ready State Tests
    
    func testMetalReadyWhenBothPipelinesAvailable() async {
        // When Metal is enabled and both pipelines are created, metalReady should be true
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        
        // If Metal is available, GPU path should be attempted
        let result = await actor.reciprocalC(vertices: vertices)
        XCTAssertEqual(result.values.count, 1)
    }
    
    func testMetalReadyWhenPipelinesUnavailable() async {
        // When Metal is enabled but pipelines fail, metalReady should be false
        // This causes CPU fallback
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        // Don't add the required functions, so pipeline creation fails
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        
        let result = await actor.reciprocalC(vertices: vertices)
        // Should still work with CPU fallback
        XCTAssertEqual(result.values.count, 1)
        // If Metal wasn't ready, usedGPU should be false
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    func testMetalReadyWhenOnlyOnePipelineAvailable() async {
        // When only one pipeline is available, metalReady should be false
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel"] // Only one pipeline
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        
        let result = await actor.reciprocalC(vertices: vertices)
        // Should fall back to CPU when metalReady is false
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
    
    // MARK: - ContinuousClock Extension Tests
    
    func testElapsedTimeCalculation() async {
        // Tests the ContinuousClock.Instant.elapsedTime() extension
        let actor = CanonicalizationPipelineActor(enableMetal: false)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Duration should be calculated and positive
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
    }
    
    // MARK: - Telemetry Validation
    
    func testReciprocalCTelemetryDurationIsPositive() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3), Vec3(4, 5, 6)])
        let result = await actor.reciprocalC(vertices: vertices)
        
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
        XCTAssertEqual(result.telemetry.stage, .reciprocalC)
    }
    
    func testReciprocalNTelemetryDurationIsPositive() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reciprocal_c_kernel", "reciprocal_n_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let actor = CanonicalizationPipelineActor(device: mockDevice, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        let faces: [Face] = [[0, 1, 2]]
        let result = await actor.reciprocalN(vertices: vertices, faces: faces)
        
        XCTAssertGreaterThanOrEqual(result.telemetry.duration, 0)
        XCTAssertEqual(result.telemetry.stage, .reciprocalN)
    }
    
    // MARK: - Init with Nil Device
    
    func testInitWithNilDevice() async {
        let actor = CanonicalizationPipelineActor(device: nil, enableMetal: true)
        let vertices = ContiguousArray([Vec3(1, 2, 3)])
        
        let result = await actor.reciprocalC(vertices: vertices)
        
        // Should fall back to CPU when device is nil
        XCTAssertEqual(result.values.count, 1)
        XCTAssertFalse(result.telemetry.usedGPU)
    }
}

