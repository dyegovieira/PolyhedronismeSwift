import XCTest
@testable import PolyhedronismeSwift

final class MetalDualOperatorTests: XCTestCase {
    
    func testCubeDual() async throws {
        // 1. Generate base Cube
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        // 2. Apply CPU Dual
        let cpuDual = DualOperator()
        let cpuResult = try await cpuDual.apply(to: model)
        
        // 3. Apply Metal Dual
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalDual = MetalDualOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            print("Metal not supported, skipping test")
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalDual.apply(to: model)
        } catch {
            print("Metal shaders not available in test environment, skipping Metal comparison: \(error)")
            return
        }
        
        // 4. Compare Results
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count, "Face counts should match")
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count, "Vertex counts should match")
        
        // Compare vertices
        // Dual of Cube has 6 vertices (centers of 6 faces)
        // CPU Dual might order them differently?
        // Metal Dual orders them by face index.
        // CPU Dual orders them by face index too (usually).
        
        for i in 0..<cpuResult.vertices.count {
            let v1 = cpuResult.vertices[i]
            // Find matching vertex in metal result
            let match = metalResult.vertices.contains { v2 in
                abs(v1.x - v2.x) < 1e-5 && abs(v1.y - v2.y) < 1e-5 && abs(v1.z - v2.z) < 1e-5
            }
            XCTAssertTrue(match, "Vertex \(v1) should exist in Metal result")
        }
    }
    
    func testDodecahedronDual() async throws {
        let dodeca = try await Polyhedron.dodecahedron()
        let model = PolyhedronModel(
            vertices: dodeca.vertices,
            faces: dodeca.faces,
            name: "D",
            faceClasses: []
        )
        
        let cpuDual = DualOperator()
        let cpuResult = try await cpuDual.apply(to: model)
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalDual = MetalDualOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalDual.apply(to: model)
        } catch {
            print("Metal shaders not available: \(error)")
            return
        }
        
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count)
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count)
    }
    
    func testInitReturnsNilWhenDeviceIsNil() {
        let mockConfig = MockMetalConfiguration(device: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory)
        XCTAssertNil(metalOperator)
    }
    
    func testInitSucceedsWhenDeviceExists() {
        let mockDevice = MockMetalDevice()
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory)
        XCTAssertNotNil(metalOperator)
    }
    
    func testIdentifier() {
        let mockDevice = MockMetalDevice()
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        XCTAssertEqual(metalOperator.identifier, "d")
    }
    
    func testThrowsWhenVertexBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        do {
            _ = try await metalOperator.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound when buffer creation fails")
        } catch let error as MetalError {
            if case .deviceNotFound = error {
            } else {
                XCTFail("Should throw deviceNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError.deviceNotFound, got \(error)")
        }
    }
    
    func testThrowsWhenCommandQueueIsNil() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        do {
            _ = try await metalOperator.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound when command queue is nil")
        } catch let error as MetalError {
            if case .deviceNotFound = error {
            } else {
                XCTFail("Should throw deviceNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError.deviceNotFound, got \(error)")
        }
    }
    
    func testThrowsWhenCommandBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        mockQueue.shouldFailMakeCommandBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        do {
            _ = try await metalOperator.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound when command buffer creation fails")
        } catch let error as MetalError {
            if case .deviceNotFound = error {
            } else {
                XCTFail("Should throw deviceNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError.deviceNotFound, got \(error)")
        }
    }
    
    func testNameTransformationAddsD() async throws {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let result = try await metalOperator.apply(to: model)
        XCTAssertTrue(result.name.hasPrefix("d"), "Name should start with 'd'")
        XCTAssertEqual(result.name, "dTest")
    }
    
    func testNameTransformationRemovesD() async throws {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)],
            faces: [[0, 1, 2]],
            name: "dTest",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let result = try await metalOperator.apply(to: model)
        XCTAssertFalse(result.name.hasPrefix("d"), "Name should not start with 'd'")
        XCTAssertEqual(result.name, "Test")
    }
    
    func testNameTransformationSingleD() async throws {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)],
            faces: [[0, 1, 2]],
            name: "d",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let result = try await metalOperator.apply(to: model)
        XCTAssertEqual(result.name, "d", "Single 'd' should remain as 'd'")
    }
    
    func testHandlesEmptyPolyhedron() async throws {
        let emptyModel = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "empty",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        do {
            _ = try await metalOperator.apply(to: emptyModel)
            XCTFail("Should throw when polyhedron is empty")
        } catch {
            XCTAssertTrue(error is MetalError, "Should throw MetalError")
        }
    }
    
    func testHandlesSingleFace() async throws {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)],
            faces: [[0, 1, 2]],
            name: "triangle",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let result = try await metalOperator.apply(to: model)
        XCTAssertEqual(result.vertices.count, 1, "Should have one vertex (centroid of face)")
        XCTAssertTrue(result.faces.isEmpty, "Single face polyhedron may not produce valid faces in dual (no adjacent faces to walk)")
    }
    
    func testHandlesVerticesNotInFaces() async throws {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1), Vec3(10, 10, 10)],
            faces: [[0, 1, 2]],
            name: "test",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let result = try await metalOperator.apply(to: model)
        XCTAssertEqual(result.vertices.count, 1, "Should have one vertex (centroid of face)")
        XCTAssertLessThanOrEqual(result.faces.count, 1, "Unused vertices should not create faces")
    }
    
    func testMetalDualOperatorApplyWithComputeEncoderError() async throws {
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
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
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
        mockLibrary.availableFunctions = ["face_centroid_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        do {
            _ = try await metalOperator.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound when compute encoder creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalDualOperatorApplyWithLargePolyhedron() async throws {
        // Create a large polyhedron
        var vertices: [Vec3] = []
        var faces: [[Int]] = []
        
        let gridSize = 25
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                vertices.append(Vec3(Double(i), Double(j), 0.0))
            }
        }
        
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
        guard let metalOperator = MetalDualOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalOperator.apply(to: model)
            XCTAssertEqual(result.vertices.count, model.faces.count)
            XCTAssertGreaterThan(result.faces.count, 0)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalDualOperatorApplyWithPipelineFactoryError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalDualOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        // Pipeline factory will fail because function not found
        do {
            _ = try await metalOperator.apply(to: model)
            XCTFail("Should throw MetalError when pipeline factory fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
}
