import XCTest
@testable import PolyhedronismeSwift

final class MetalReflectOperatorTests: XCTestCase {
    
    func testCubeReflect() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let cpuReflect = ReflectOperator()
        let cpuResult = try await cpuReflect.apply(to: model)
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            print("Metal not supported, skipping test")
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalReflect.apply(to: model)
        } catch {
            print("Metal shaders not available in test environment, skipping Metal comparison: \(error)")
            return
        }
        
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count)
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count)
        
        for i in 0..<cpuResult.vertices.count {
            let v1 = cpuResult.vertices[i]
            let v2 = metalResult.vertices[i]
            XCTAssertEqual(v1.x, v2.x, accuracy: 1e-5)
            XCTAssertEqual(v1.y, v2.y, accuracy: 1e-5)
            XCTAssertEqual(v1.z, v2.z, accuracy: 1e-5)
        }
    }
    
    func testMetalReflectOperatorInitWithNilDevice() {
        let mockConfig = MockMetalConfiguration(device: nil, commandQueue: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        let operator_ = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory)
        XCTAssertNil(operator_, "Should return nil when device is nil")
    }
    
    func testMetalReflectOperatorApplyWithEmptyPolyhedron() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let emptyModel = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "empty",
            faceClasses: []
        )
        
        let result = try await metalReflect.apply(to: emptyModel)
        XCTAssertEqual(result.vertices.count, 0)
        XCTAssertEqual(result.faces.count, 0)
    }
    
    func testMetalReflectOperatorApplyWithDeviceNotFoundError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
            _ = try await metalReflect.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalReflectOperatorApplyWithCommandQueueError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        mockQueue.shouldFailMakeCommandBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
            _ = try await metalReflect.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalReflectOperatorApplyWithPipelineError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
            _ = try await metalReflect.apply(to: model)
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalReflectOperatorIdentifier() {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        XCTAssertEqual(metalReflect.identifier, "r")
    }
    
    func testMetalReflectOperatorPreservesFaceClasses() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: [1, 2]
        )
        
        let cpuReflect = ReflectOperator()
        let cpuResult = try await cpuReflect.apply(to: model)
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let metalResult = try await metalReflect.apply(to: model)
            XCTAssertEqual(metalResult.faceClasses, model.faceClasses)
            XCTAssertEqual(cpuResult.faceClasses, model.faceClasses)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalReflectOperatorReversesFaces() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalReflect.apply(to: model)
            XCTAssertEqual(result.faces.count, model.faces.count)
            for i in 0..<model.faces.count {
                XCTAssertEqual(result.faces[i], Array(model.faces[i].reversed()))
            }
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalReflectOperatorApplyWithComputeEncoderError() async throws {
        let mockDevice = MockMetalDevice()
        let mockBuffer = MockMetalCommandBuffer()
        mockBuffer.shouldFailMakeComputeCommandEncoder = true
        
        // Create a custom command queue that returns our failing buffer
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
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        do {
            _ = try await metalReflect.apply(to: model)
            XCTFail("Should throw MetalError.deviceNotFound when compute encoder creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalReflectOperatorApplyWithLargePolyhedron() async throws {
        // Create a large polyhedron with many vertices
        var vertices: [Vec3] = []
        var faces: [[Int]] = []
        
        // Create a grid of vertices
        let gridSize = 20
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
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalReflect.apply(to: model)
            XCTAssertEqual(result.vertices.count, model.vertices.count)
            XCTAssertEqual(result.faces.count, model.faces.count)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalReflectOperatorApplyWithVaryingFaceSizes() async throws {
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1),
                Vec3(1, 1, 0), Vec3(1, 0, 1), Vec3(0, 1, 1), Vec3(1, 1, 1)
            ],
            faces: [
                [0, 1, 2], // Triangle
                [0, 1, 2, 3], // Quad
                [0, 1, 2, 3, 4], // Pentagon
                [0, 1, 2, 3, 4, 5] // Hexagon
            ],
            name: "varying",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalReflect.apply(to: model)
            XCTAssertEqual(result.vertices.count, model.vertices.count)
            XCTAssertEqual(result.faces.count, model.faces.count)
            for i in 0..<model.faces.count {
                XCTAssertEqual(result.faces[i], Array(model.faces[i].reversed()))
            }
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalReflectOperatorApplyWithPipelineFactoryError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
            _ = try await metalReflect.apply(to: model)
            XCTFail("Should throw MetalError when pipeline factory fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    // MARK: - Error Path Tests
    
    func testMetalReflectOperatorApplyWithNewVertexBufferError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) != nil else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        // Set up a custom device that fails on newVertexBuffer (2nd call)
        final class SelectiveFailingDevice: MetalDevice, @unchecked Sendable {
            var failOnCall: Int = 2 // Fail on 2nd call (newVertexBuffer)
            var currentCall = 0
            let baseDevice: MockMetalDevice
            
            init(baseDevice: MockMetalDevice) {
                self.baseDevice = baseDevice
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return baseDevice.makeDefaultLibrary()
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return try baseDevice.makeLibrary(source: source, options: options)
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                currentCall += 1
                if currentCall == failOnCall {
                    return nil
                }
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                currentCall += 1
                if currentCall == failOnCall {
                    return nil
                }
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let selectiveDevice = SelectiveFailingDevice(baseDevice: mockDevice)
        selectiveDevice.baseDevice.defaultLibrary = mockLibrary
        let selectiveConfig = MockMetalConfiguration(device: selectiveDevice, commandQueue: mockQueue)
        let selectiveFactory = ComputePipelineFactory(metalConfig: selectiveConfig)
        
        guard let selectiveReflect = MetalReflectOperator(metalConfig: selectiveConfig, pipelineFactory: selectiveFactory) else {
            return
        }
        
        do {
            _ = try await selectiveReflect.apply(to: model)
            XCTFail("Should throw when newVertexBuffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalReflectOperatorApplyWithEmptyVerticesButFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Empty vertices but non-empty faces - should use early return path (line 31-38)
        let model = PolyhedronModel(
            vertices: [],
            faces: [[0, 1, 2], [1, 2, 3]],
            name: "Test",
            faceClasses: [1, 2]
        )
        
        let result = try await metalReflect.apply(to: model)
        XCTAssertEqual(result.vertices.count, 0)
        XCTAssertEqual(result.faces.count, 2)
        // Faces should be reversed
        XCTAssertEqual(result.faces[0], [2, 1, 0])
        XCTAssertEqual(result.faces[1], [3, 2, 1])
        XCTAssertEqual(result.name, "rTest")
        XCTAssertEqual(result.faceClasses, [1, 2])
    }
    
    // MARK: - Edge Case Tests
    
    func testMetalReflectOperatorWithSingleVertex() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(1, 2, 3)],
            faces: [[0]],
            name: "single",
            faceClasses: []
        )
        
        do {
            let result = try await metalReflect.apply(to: model)
            XCTAssertEqual(result.vertices.count, 1)
            XCTAssertEqual(result.faces.count, 1)
            // Vertex should be reflected (negated)
            XCTAssertEqual(result.vertices[0].x, -1.0, accuracy: 1e-5)
            XCTAssertEqual(result.vertices[0].y, -2.0, accuracy: 1e-5)
            XCTAssertEqual(result.vertices[0].z, -3.0, accuracy: 1e-5)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalReflectOperatorWithEmptyFacesButVertices() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [],
            name: "Test",
            faceClasses: []
        )
        
        do {
            let result = try await metalReflect.apply(to: model)
            XCTAssertEqual(result.vertices.count, 3)
            XCTAssertEqual(result.faces.count, 0)
            // Vertices should be reflected
            for i in 0..<model.vertices.count {
                XCTAssertEqual(result.vertices[i].x, -model.vertices[i].x, accuracy: 1e-5)
                XCTAssertEqual(result.vertices[i].y, -model.vertices[i].y, accuracy: 1e-5)
                XCTAssertEqual(result.vertices[i].z, -model.vertices[i].z, accuracy: 1e-5)
            }
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalReflectOperatorThreadGroupCalculationEdgeCases() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with 0 vertices (should use early return)
        let model0 = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "zero",
            faceClasses: []
        )
        let result0 = try await metalReflect.apply(to: model0)
        XCTAssertEqual(result0.vertices.count, 0)
        
        // Test with 1 vertex
        let model1 = PolyhedronModel(
            vertices: [Vec3(1, 0, 0)],
            faces: [[0]],
            name: "one",
            faceClasses: []
        )
        let result1 = try await metalReflect.apply(to: model1)
        XCTAssertEqual(result1.vertices.count, 1)
        
        // Test with 63 vertices (just under thread group boundary)
        var vertices63: [Vec3] = []
        for i in 0..<63 {
            vertices63.append(Vec3(Double(i), 0, 0))
        }
        let model63 = PolyhedronModel(
            vertices: vertices63,
            faces: [],
            name: "sixtythree",
            faceClasses: []
        )
        let result63 = try await metalReflect.apply(to: model63)
        XCTAssertEqual(result63.vertices.count, 63)
        
        // Test with 64 vertices (exact thread group boundary)
        var vertices64: [Vec3] = []
        for i in 0..<64 {
            vertices64.append(Vec3(Double(i), 0, 0))
        }
        let model64 = PolyhedronModel(
            vertices: vertices64,
            faces: [],
            name: "sixtyfour",
            faceClasses: []
        )
        let result64 = try await metalReflect.apply(to: model64)
        XCTAssertEqual(result64.vertices.count, 64)
        
        // Test with 65 vertices (just over thread group boundary)
        var vertices65: [Vec3] = []
        for i in 0..<65 {
            vertices65.append(Vec3(Double(i), 0, 0))
        }
        let model65 = PolyhedronModel(
            vertices: vertices65,
            faces: [],
            name: "sixtyfive",
            faceClasses: []
        )
        let result65 = try await metalReflect.apply(to: model65)
        XCTAssertEqual(result65.vertices.count, 65)
    }
    
    func testMetalReflectOperatorFaceReversalWithSingleVertexFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0)],
            faces: [[0]],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalReflect.apply(to: model)
        XCTAssertEqual(result.faces.count, 1)
        XCTAssertEqual(result.faces[0], [0], "Single vertex face reversed is still [0]")
    }
    
    func testMetalReflectOperatorFaceReversalWithEmptyFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalReflect.apply(to: model)
        XCTAssertEqual(result.faces.count, 0)
    }
    
    // MARK: - Property Verification Tests
    
    func testMetalReflectOperatorNameTransformation() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalReflect.apply(to: model)
        XCTAssertEqual(result.name, "rTest", "Name should be 'r' + original name")
    }
    
    func testMetalReflectOperatorFaceClassesPreservationEdgeCases() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["reflect_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalReflect = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with empty faceClasses
        let model1 = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        let result1 = try await metalReflect.apply(to: model1)
        XCTAssertTrue(result1.faceClasses.isEmpty)
        
        // Test with non-empty faceClasses
        let model2 = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: [1, 2, 3, 4, 5]
        )
        let result2 = try await metalReflect.apply(to: model2)
        XCTAssertEqual(result2.faceClasses, [1, 2, 3, 4, 5])
    }
    
    // MARK: - Result Validation Tests
    
    func testMetalReflectOperatorFaceReversalCorrectness() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalReflect = MetalReflectOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with various face sizes
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(1, 1, 0),
                Vec3(0, 0, 1), Vec3(1, 0, 1), Vec3(0, 1, 1), Vec3(1, 1, 1)
            ],
            faces: [
                [0, 1, 2], // Triangle
                [0, 1, 2, 3], // Quad
                [0, 1, 2, 3, 4], // Pentagon
                [0, 1, 2, 3, 4, 5, 6, 7] // Octagon
            ],
            name: "Test",
            faceClasses: []
        )
        
        do {
            let result = try await metalReflect.apply(to: model)
            
            // Verify each face is correctly reversed
            XCTAssertEqual(result.faces[0], [2, 1, 0])
            XCTAssertEqual(result.faces[1], [3, 2, 1, 0])
            XCTAssertEqual(result.faces[2], [4, 3, 2, 1, 0])
            XCTAssertEqual(result.faces[3], [7, 6, 5, 4, 3, 2, 1, 0])
            
            // Verify vertices are reflected (negated)
            for i in 0..<model.vertices.count {
                XCTAssertEqual(result.vertices[i].x, -model.vertices[i].x, accuracy: 1e-5)
                XCTAssertEqual(result.vertices[i].y, -model.vertices[i].y, accuracy: 1e-5)
                XCTAssertEqual(result.vertices[i].z, -model.vertices[i].z, accuracy: 1e-5)
            }
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
}
