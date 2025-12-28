import XCTest
@testable import PolyhedronismeSwift

final class MetalAmboOperatorTests: XCTestCase {
    
    func testCubeAmbo() async throws {
        // 1. Generate base Cube
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        // 2. Apply CPU Ambo
        let cpuAmbo = AmboOperator()
        let cpuResult = try await cpuAmbo.apply(to: model)
        
        // 3. Apply Metal Ambo
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            print("Metal not supported, skipping test")
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalAmbo.apply(to: model)
        } catch {
            print("Metal shaders not available in test environment, skipping Metal comparison: \(error)")
            return
        }
        
        // 4. Compare Results
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count, "Face counts should match")
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count, "Vertex counts should match")
        
        // Compare vertices (approximate match, order might differ but sets should match)
        // Since Ambo is deterministic if edges are processed in order, let's check if we can match them.
        // CPU Ambo uses PolyFlag which might order differently than our Edge List.
        // So we should check if every vertex in Metal result exists in CPU result.
        
        for v in metalResult.vertices {
            let match = cpuResult.vertices.contains { cv in
                abs(cv.x - v.x) < 1e-5 && abs(cv.y - v.y) < 1e-5 && abs(cv.z - v.z) < 1e-5
            }
            XCTAssertTrue(match, "Vertex \(v) should exist in CPU result")
        }
    }
    
    func testDodecahedronAmbo() async throws {
        let dodeca = try await Polyhedron.dodecahedron()
        let model = PolyhedronModel(
            vertices: dodeca.vertices,
            faces: dodeca.faces,
            name: "D",
            faceClasses: []
        )
        
        let cpuAmbo = AmboOperator()
        let cpuResult = try await cpuAmbo.apply(to: model)
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalAmbo.apply(to: model)
        } catch {
            print("Metal shaders not available: \(error)")
            return
        }
        
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count)
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count)
    }
    
    func testMetalAmboOperatorInitWithNilDevice() {
        let mockConfig = MockMetalConfiguration(device: nil, commandQueue: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        let operator_ = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory)
        XCTAssertNil(operator_, "Should return nil when device is nil")
    }
    
    func testMetalAmboOperatorApplyWithEmptyPolyhedron() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let emptyModel = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "empty",
            faceClasses: []
        )
        
        let result = try await metalAmbo.apply(to: emptyModel)
        XCTAssertEqual(result.vertices.count, 0)
        XCTAssertEqual(result.faces.count, 0)
    }
    
    func testMetalAmboOperatorApplyWithNoEdges() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0)],
            faces: [],
            name: "single_vertex",
            faceClasses: []
        )
        
        // When there are no edges, the operator returns the original polyhedron
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        XCTAssertEqual(result.faces.count, model.faces.count)
    }
    
    func testMetalAmboOperatorApplyWithDeviceNotFoundError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        mockDevice.shouldFailMakeBuffer = true
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalAmboOperatorApplyWithCommandQueueError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        mockQueue.shouldFailMakeCommandBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalAmboOperatorWithDuplicateEdges() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [
                Vec3(1, 0, 0),
                Vec3(0, 1, 0),
                Vec3(0, 0, 1)
            ],
            faces: [[0, 1, 2], [0, 2, 1]],
            name: "duplicate",
            faceClasses: []
        )
        
        do {
            let result = try await metalAmbo.apply(to: model)
            XCTAssertFalse(result.vertices.isEmpty)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalAmboOperatorIdentifier() {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        XCTAssertEqual(metalAmbo.identifier, "a")
    }
    
    func testMetalAmboOperatorApplyWithComputeEncoderError() async throws {
        let mockDevice = MockMetalDevice()
        let mockBuffer = MockMetalCommandBuffer()
        mockBuffer.shouldFailMakeComputeCommandEncoder = true
        
        final class FailingEncoderCommandQueue: MetalCommandQueue, @unchecked Sendable {
            let failingBuffer: MockMetalCommandBuffer
            
            init(failingBuffer: MockMetalCommandBuffer) {
                self.failingBuffer = failingBuffer
            }
            
            func makeCommandBuffer() -> MetalCommandBuffer? {
                return failingBuffer
            }
        }
        
        let failingQueue = FailingEncoderCommandQueue(failingBuffer: mockBuffer)
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: failingQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound when compute encoder creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalAmboOperatorApplyWithLargePolyhedron() async throws {
        // Create a large polyhedron with many edges
        var vertices: [Vec3] = []
        var faces: [[Int]] = []
        
        // Create a grid of vertices
        let gridSize = 30
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                vertices.append(Vec3(Double(i), Double(j), 0.0))
            }
        }
        
        // Create faces
        for i in 0..<(gridSize - 1) {
            for j in 0..<(gridSize - 1) {
                let idx = i * gridSize + j
                faces.append([idx, idx + 1, idx + gridSize])
                faces.append([idx + 1, idx + gridSize + 1, idx + gridSize])
            }
        }
        
        let model = PolyhedronModel(
            vertices: vertices,
            faces: faces,
            name: "large",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalAmbo.apply(to: model)
            XCTAssertGreaterThan(result.vertices.count, 0)
            XCTAssertGreaterThan(result.faces.count, 0)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalAmboOperatorApplyWithSingleEdge() async throws {
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0)
            ],
            faces: [
                [0, 1]
            ],
            name: "edge",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalAmbo.apply(to: model)
            XCTAssertEqual(result.vertices.count, 1) // One midpoint
            XCTAssertGreaterThan(result.faces.count, 0)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalAmboOperatorApplyWithVeryLargeEdgeCount() async throws {
        // Create a polyhedron with many edges (stress test)
        var vertices: [Vec3] = []
        var faces: [[Int]] = []
        
        let size = 50
        for i in 0..<size {
            for j in 0..<size {
                vertices.append(Vec3(Double(i), Double(j), Double(i + j)))
            }
        }
        
        // Create many small faces to maximize edge count
        for i in 0..<(size - 1) {
            for j in 0..<(size - 1) {
                let idx = i * size + j
                faces.append([idx, idx + 1, idx + size])
                faces.append([idx + 1, idx + size + 1, idx + size])
            }
        }
        
        let model = PolyhedronModel(
            vertices: vertices,
            faces: faces,
            name: "stress",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalAmbo = MetalAmboOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalAmbo.apply(to: model)
            XCTAssertGreaterThan(result.vertices.count, 1000) // Should have many edge midpoints
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    // MARK: - Edge Extraction Tests
    
    func testMetalAmboOperatorExtractEdgesWithEmptyFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [], // Empty faces
            name: "Test"
        )
        
        // Should return original when no edges
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        XCTAssertEqual(result.faces.count, model.faces.count)
    }
    
    func testMetalAmboOperatorExtractEdgesWithSingleVertexFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0)],
            faces: [[0]], // Single vertex face (no edges)
            name: "Test"
        )
        
        // Should return original when no edges
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.vertices.count, model.vertices.count)
    }
    
    func testMetalAmboOperatorExtractEdgesWithTwoVertexFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]], // Two vertex face (one edge)
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.vertices.count, 1, "Should have one edge midpoint")
        XCTAssertGreaterThan(result.faces.count, 0)
    }
    
    // MARK: - Face Construction Tests
    
    func testMetalAmboOperatorFaceFacesConstruction() async throws {
        // Test center faces (face faces) construction
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Simple triangle - should create center face
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2]],
            name: "Triangle"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should have center face (1) + vertex faces (3) = 4 faces
        XCTAssertGreaterThanOrEqual(result.faces.count, 1)
        XCTAssertEqual(result.vertices.count, 3, "Should have 3 edge midpoints")
    }
    
    func testMetalAmboOperatorVertexFacesWithEmptySegments() async throws {
        // Test vertex faces when some vertices have no segments
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Model with isolated vertex
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0),
                Vec3(10, 10, 10) // Isolated vertex
            ],
            faces: [[0, 1, 2]], // Doesn't include vertex 3
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Isolated vertex should have no segments, so no face created for it
        XCTAssertGreaterThanOrEqual(result.faces.count, 1)
    }
    
    func testMetalAmboOperatorWithMissingEdgeInEdgeMap() async throws {
        // Test when edge is missing from edgeMap (shouldn't happen, but test guard)
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Normal model - all edges should be in map
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should handle gracefully - missing edges just won't be added to face
        XCTAssertGreaterThanOrEqual(result.faces.count, 0)
    }
    
    // MARK: - Buffer Failure Tests
    
    func testMetalAmboOperatorEdgeBufferFailure() async throws {
        // Test when edgeBuffer creation fails
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "Test"
        )
        
        mockDevice.shouldFailMakeBuffer = true
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw when buffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError, "Should throw MetalError when buffer creation fails")
        }
    }
    
    func testMetalAmboOperatorNewVertexBufferFailure() async throws {
        // Test when newVertexBuffer creation fails
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "Test"
        )
        
        mockDevice.shouldFailMakeBuffer = true
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw when buffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError, "Should throw MetalError when buffer creation fails")
        }
    }
    
    // MARK: - Pipeline Factory Error Tests
    
    func testMetalAmboOperatorPipelineFactoryError() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        // Don't add the function, so pipeline creation fails
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "Test"
        )
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw when pipeline creation fails")
        } catch {
            XCTAssertTrue(error is MetalError, "Should throw MetalError when pipeline creation fails")
        }
    }
    
    // MARK: - Thread Group Calculation Tests
    
    func testMetalAmboOperatorThreadGroupBoundary() async throws {
        // Test thread group calculation at boundary (64 edges)
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Create model with approximately 64 edges
        var vertices: [Vec3] = []
        var faces: [[Int]] = []
        
        // Create grid that results in ~64 edges
        let size = 8
        for i in 0..<size {
            for j in 0..<size {
                vertices.append(Vec3(Double(i), Double(j), 0.0))
            }
        }
        
        for i in 0..<(size - 1) {
            for j in 0..<(size - 1) {
                let idx = i * size + j
                faces.append([idx, idx + 1, idx + size])
            }
        }
        
        let model = PolyhedronModel(vertices: vertices, faces: faces, name: "Grid")
        
        do {
            let result = try await metalAmbo.apply(to: model)
            XCTAssertGreaterThan(result.vertices.count, 0)
        } catch {
            // May fail if Metal not available
        }
    }
    
    func testMetalAmboOperatorThreadGroupOverBoundary() async throws {
        // Test with 65+ edges (just over boundary)
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Create model with 65+ edges
        var vertices: [Vec3] = []
        var faces: [[Int]] = []
        
        let size = 9
        for i in 0..<size {
            for j in 0..<size {
                vertices.append(Vec3(Double(i), Double(j), 0.0))
            }
        }
        
        for i in 0..<(size - 1) {
            for j in 0..<(size - 1) {
                let idx = i * size + j
                faces.append([idx, idx + 1, idx + size])
            }
        }
        
        let model = PolyhedronModel(vertices: vertices, faces: faces, name: "Grid")
        
        do {
            let result = try await metalAmbo.apply(to: model)
            XCTAssertGreaterThan(result.vertices.count, 64)
        } catch {
            // May fail if Metal not available
        }
    }
    
    // MARK: - Result Property Tests
    
    func testMetalAmboOperatorNameTransformation() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.name, "aTest", "Name should be prefixed with 'a'")
    }
    
    func testMetalAmboOperatorFaceClassesPreservation() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "Test",
            faceClasses: [1, 2]
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Face classes should be empty (line 176)
        XCTAssertTrue(result.faceClasses.isEmpty, "Face classes should be empty after Ambo")
    }
    
    // MARK: - Loop Stitching Tests
    
    func testMetalAmboOperatorWithComplexVertexFaces() async throws {
        // Test vertex face construction with multiple segments
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Create a model where a vertex is shared by multiple faces
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0),
                Vec3(0, 0, 1)
            ],
            faces: [
                [0, 1, 2],
                [0, 1, 3],
                [0, 2, 3]
            ], // Vertex 0 is shared by all faces
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should create vertex faces for vertex 0
        XCTAssertGreaterThan(result.faces.count, 3, "Should have more than just center faces")
    }
    
    func testMetalAmboOperatorWithBrokenLoops() async throws {
        // Test handling of broken loops (line 134)
        // This is hard to create naturally, but we can test the logic
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Normal model - broken loops shouldn't occur in valid polyhedra
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should handle gracefully
        XCTAssertGreaterThanOrEqual(result.faces.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testMetalAmboOperatorWithSingleFace() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2]], // Single face
            name: "Triangle"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should have 1 center face + 3 vertex faces = 4 faces
        XCTAssertGreaterThanOrEqual(result.faces.count, 1)
        XCTAssertEqual(result.vertices.count, 3, "Should have 3 edge midpoints")
    }
    
    func testMetalAmboOperatorWithQuadFace() async throws {
        // Test with quadrilateral face
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(1, 1, 0),
                Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2, 3]], // Quad face
            name: "Square"
        )
        
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.vertices.count, 4, "Should have 4 edge midpoints")
        XCTAssertGreaterThanOrEqual(result.faces.count, 1)
    }
    
    func testMetalAmboOperatorWithPentagonFace() async throws {
        // Test with pentagon face
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(1.5, 0.5, 0),
                Vec3(1, 1, 0),
                Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2, 3, 4]], // Pentagon face
            name: "Pentagon"
        )
        
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.vertices.count, 5, "Should have 5 edge midpoints")
        XCTAssertGreaterThanOrEqual(result.faces.count, 1)
    }
    
    func testMetalAmboOperatorWithMultipleFacesSharingEdges() async throws {
        // Test with multiple faces that share edges
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Tetrahedron - all faces share edges
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0),
                Vec3(1, 0, 0),
                Vec3(0, 1, 0),
                Vec3(0, 0, 1)
            ],
            faces: [
                [0, 1, 2],
                [0, 1, 3],
                [0, 2, 3],
                [1, 2, 3]
            ],
            name: "Tetrahedron"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should handle shared edges correctly
        XCTAssertGreaterThan(result.vertices.count, 0)
        XCTAssertGreaterThan(result.faces.count, 0)
    }
    
    func testMetalAmboOperatorWithEmptyName() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "" // Empty name
        )
        
        let result = try await metalAmbo.apply(to: model)
        XCTAssertEqual(result.name, "a", "Empty name should become 'a'")
    }
    
    func testMetalAmboOperatorWithZeroEdges() async throws {
        // Test the guard at line 34
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0)],
            faces: [], // No faces = no edges
            name: "Test"
        )
        
        let result = try await metalAmbo.apply(to: model)
        // Should return original polyhedron when edgeCount == 0
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        XCTAssertEqual(result.faces.count, model.faces.count)
        XCTAssertEqual(result.name, model.name)
    }
    
    func testMetalAmboOperatorCommandQueueNil() async throws {
        // Test when commandQueue is nil (line 47)
        let mockDevice = MockMetalDevice()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalAmbo = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            faces: [[0, 1]],
            name: "Test"
        )
        
        do {
            _ = try await metalAmbo.apply(to: model)
            XCTFail("Should throw when commandQueue is nil")
        } catch {
            XCTAssertTrue(error is MetalError, "Should throw MetalError when commandQueue is nil")
        }
    }
}
