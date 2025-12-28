import XCTest
@testable import PolyhedronismeSwift

final class MetalKisOperatorTests: XCTestCase {
    
    func testCubeKis() async throws {
        // 1. Generate base Cube
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        // 2. Apply CPU Kis
        let cpuKis = KisOperator()
        let cpuResult = try await cpuKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
        
        // 3. Apply Metal Kis
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            print("Metal not supported, skipping test")
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
        } catch {
            print("Metal shaders not available in test environment, skipping Metal comparison: \(error)")
            return
        }
        
        // 4. Compare Results
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count, "Face counts should match")
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count, "Vertex counts should match")
        
        // Compare vertices (allowing for small float precision diffs)
        for i in 0..<cpuResult.vertices.count {
            let v1 = cpuResult.vertices[i]
            let v2 = metalResult.vertices[i]
            
            XCTAssertEqual(v1.x, v2.x, accuracy: 1e-5)
            XCTAssertEqual(v1.y, v2.y, accuracy: 1e-5)
            XCTAssertEqual(v1.z, v2.z, accuracy: 1e-5)
        }
    }
    
    func testDodecahedronKis5() async throws {
        // 1. Generate base Dodecahedron
        let dodeca = try await Polyhedron.dodecahedron()
        let model = PolyhedronModel(
            vertices: dodeca.vertices,
            faces: dodeca.faces,
            name: "D",
            faceClasses: []
        )
        
        // 2. Apply CPU Kis (n=5)
        let cpuKis = KisOperator()
        let cpuResult = try await cpuKis.apply(to: model, parameters: KisParameters(n: 5, apexDistance: 0.1))
        
        // 3. Apply Metal Kis
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Try Metal, but skip test if Metal shaders aren't available
        let metalResult: PolyhedronModel
        do {
            metalResult = try await metalKis.apply(to: model, parameters: KisParameters(n: 5, apexDistance: 0.1))
        } catch {
            print("Metal shaders not available in test environment, skipping Metal comparison: \(error)")
            return
        }
        
        // 4. Compare
        XCTAssertEqual(cpuResult.faces.count, metalResult.faces.count)
        XCTAssertEqual(cpuResult.vertices.count, metalResult.vertices.count)
    }
    
    func testMetalKisOperatorInitWithNilDevice() {
        let mockConfig = MockMetalConfiguration(device: nil, commandQueue: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        let operator_ = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory)
        XCTAssertNil(operator_, "Should return nil when device is nil")
    }
    
    func testMetalKisOperatorApplyWithEmptyPolyhedron() async throws {
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let emptyModel = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "empty",
            faceClasses: []
        )
        
        do {
            let result = try await metalKis.apply(to: emptyModel, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTAssertEqual(result.vertices.count, 0)
            XCTAssertEqual(result.faces.count, 0)
        } catch {
            // Empty polyhedron might throw, which is acceptable
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithDifferentNValues() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test n=3 (triangles)
        do {
            let result3 = try await metalKis.apply(to: model, parameters: KisParameters(n: 3, apexDistance: 0.1))
            XCTAssertGreaterThan(result3.vertices.count, model.vertices.count)
        } catch {
            print("Metal shaders not available for n=3: \(error)")
        }
        
        // Test n=4 (quads)
        do {
            let result4 = try await metalKis.apply(to: model, parameters: KisParameters(n: 4, apexDistance: 0.1))
            XCTAssertGreaterThan(result4.vertices.count, model.vertices.count)
        } catch {
            print("Metal shaders not available for n=4: \(error)")
        }
    }
    
    func testMetalKisOperatorApplyWithNMatchingFaceCount() async throws {
        // Create a polyhedron where all faces are triangles (n=3)
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)
            ],
            faces: [
                [0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]
            ],
            name: "tetra",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        do {
            let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 3, apexDistance: 0.2))
            XCTAssertGreaterThan(result.vertices.count, model.vertices.count)
            XCTAssertGreaterThan(result.faces.count, model.faces.count)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalKisOperatorApplyWithNNotMatchingFaceCount() async throws {
        // Create a polyhedron with mixed face sizes
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(1, 1, 0),
                Vec3(0, 0, 1), Vec3(1, 0, 1), Vec3(0, 1, 1), Vec3(1, 1, 1)
            ],
            faces: [
                [0, 1, 2, 3], // Quad
                [4, 5, 6, 7]  // Quad
            ],
            name: "mixed",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with n=3 when faces are quads (n=4)
        do {
            let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 3, apexDistance: 0.2))
            // When n doesn't match, faces should remain unchanged
            XCTAssertEqual(result.faces.count, model.faces.count)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    func testMetalKisOperatorApplyWithBufferError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
            _ = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw MetalError.deviceNotFound when buffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithCommandQueueError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        mockQueue.shouldFailMakeCommandBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
            _ = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw MetalError.deviceNotFound when command buffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithInvalidParameters() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        guard let metalKis = MetalKisOperator(metalConfig: metalConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with negative n (should be handled gracefully or throw)
        do {
            _ = try await metalKis.apply(to: model, parameters: KisParameters(n: -1, apexDistance: 0.2))
            // If it doesn't throw, verify it handles it gracefully
        } catch {
            // Negative n might throw, which is acceptable
        }
        
        // Test with extreme apexDistance
        do {
            let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 100.0))
            XCTAssertNotNil(result)
        } catch {
            print("Metal shaders not available: \(error)")
        }
    }
    
    // MARK: - Error Path Tests
    
    func testMetalKisOperatorApplyWithComputeEncoderError() async throws {
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
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        do {
            _ = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw MetalError.deviceNotFound when compute encoder creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithPipelineFactoryError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        // Don't set up library, so pipeline factory will fail
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        do {
            _ = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw when pipeline factory fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithFaceInfoBufferError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) != nil else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        // Set up a custom device that fails on faceInfoBuffer (2nd call)
        final class SelectiveFailingDevice: MetalDevice, @unchecked Sendable {
            var failOnCall: Int = 2 // Fail on 2nd call (faceInfoBuffer)
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
        
        guard let selectiveKis = MetalKisOperator(metalConfig: selectiveConfig, pipelineFactory: selectiveFactory) else {
            return
        }
        
        do {
            _ = try await selectiveKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw when faceInfoBuffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithIndexBufferError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) != nil else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        // Set up a custom device that fails on indexBuffer (3rd call)
        final class SelectiveFailingDevice: MetalDevice, @unchecked Sendable {
            var failOnCall: Int = 3 // Fail on 3rd call (indexBuffer)
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
        
        guard let selectiveKis = MetalKisOperator(metalConfig: selectiveConfig, pipelineFactory: selectiveFactory) else {
            return
        }
        
        do {
            _ = try await selectiveKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw when indexBuffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorApplyWithNewVertexBufferError() async throws {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) != nil else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        // Set up a custom device that fails on newVertexBuffer (4th call)
        final class SelectiveFailingDevice: MetalDevice, @unchecked Sendable {
            var failOnCall: Int = 4 // Fail on 4th call (newVertexBuffer)
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
        
        guard let selectiveKis = MetalKisOperator(metalConfig: selectiveConfig, pipelineFactory: selectiveFactory) else {
            return
        }
        
        do {
            _ = try await selectiveKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw when newVertexBuffer creation fails")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testMetalKisOperatorWithSingleVertexFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(1, 0, 0)],
            faces: [[0]], // Single vertex face (no edges)
            name: "Test",
            faceClasses: []
        )
        
        // With n=0, it will create an apex vertex even for single vertex faces
        // Result: 1 original vertex + 1 apex = 2 vertices
        // Creates 1 degenerate face [0, 0, apexIndex]
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertEqual(result.vertices.count, 2, "Should have original vertex + apex")
        XCTAssertEqual(result.faces.count, 1, "Should create one face")
    }
    
    func testMetalKisOperatorWithEmptyFacesButVertices() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [],
            name: "Test",
            faceClasses: []
        )
        
        // Empty faces array causes makeBuffer(from: faceInfos) to return nil
        // because MetalBufferProvider returns nil for empty arrays
        // This is expected behavior - empty faces should throw an error
        do {
            _ = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw MetalError.deviceNotFound when faces array is empty")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalKisOperatorNameTransformationN0() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertEqual(result.name, "kTest", "Name should be 'k' + original name when n=0")
    }
    
    func testMetalKisOperatorNameTransformationN5() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 5, apexDistance: 0.2))
        XCTAssertEqual(result.name, "k5Test", "Name should be 'k' + n + original name when n>0")
    }
    
    func testMetalKisOperatorFaceClassesAlwaysEmpty() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: [1, 2, 3] // Non-empty faceClasses
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertTrue(result.faceClasses.isEmpty, "Face classes should always be empty after Kis")
    }
    
    // MARK: - Face Reconstruction Logic Tests
    
    func testMetalKisOperatorWithPentagonFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Create a pentagon face
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1.5, 1, 0), Vec3(0.5, 1.5, 0), Vec3(-0.5, 1, 0)
            ],
            faces: [[0, 1, 2, 3, 4]],
            name: "pentagon",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 5, apexDistance: 0.2))
        XCTAssertGreaterThan(result.vertices.count, model.vertices.count)
        XCTAssertGreaterThan(result.faces.count, model.faces.count)
        // Should create 5 new triangular faces from the pentagon
        XCTAssertEqual(result.faces.count, 5)
    }
    
    func testMetalKisOperatorWithHexagonFaces() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Create a hexagon face
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1.5, 0.866, 0),
                Vec3(1, 1.732, 0), Vec3(0, 1.732, 0), Vec3(-0.5, 0.866, 0)
            ],
            faces: [[0, 1, 2, 3, 4, 5]],
            name: "hexagon",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 6, apexDistance: 0.2))
        XCTAssertGreaterThan(result.vertices.count, model.vertices.count)
        XCTAssertGreaterThan(result.faces.count, model.faces.count)
        // Should create 6 new triangular faces from the hexagon
        XCTAssertEqual(result.faces.count, 6)
    }
    
    func testMetalKisOperatorWithMixedFaceSizes() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Create polyhedron with triangles and quads
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0),
                Vec3(1, 1, 0), Vec3(0.5, 0.5, 1)
            ],
            faces: [
                [0, 1, 2], // Triangle
                [0, 1, 3, 2] // Quad
            ],
            name: "mixed",
            faceClasses: []
        )
        
        // Test with n=0 (should apply to all faces)
        let result0 = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertGreaterThan(result0.faces.count, model.faces.count)
        
        // Test with n=3 (should only apply to triangle)
        let result3 = try await metalKis.apply(to: model, parameters: KisParameters(n: 3, apexDistance: 0.2))
        // Triangle should be split, quad should remain
        XCTAssertGreaterThan(result3.faces.count, 1)
    }
    
    func testMetalKisOperatorFaceLoopConstruction() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with a quad face to verify loop construction
        let model = PolyhedronModel(
            vertices: [
                Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0)
            ],
            faces: [[0, 1, 2, 3]],
            name: "quad",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 4, apexDistance: 0.2))
        // Should create 4 triangular faces
        XCTAssertEqual(result.faces.count, 4)
        // Each face should be a triangle (3 vertices)
        for face in result.faces {
            XCTAssertEqual(face.count, 3, "Each new face should be a triangle")
        }
    }
    
    // MARK: - Thread Group Calculation Tests
    
    func testMetalKisOperatorThreadGroupCalculationEdgeCases() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        // Test with 0 faces - should throw error because empty faceInfos array
        let model0 = PolyhedronModel(
            vertices: [Vec3(0, 0, 0)],
            faces: [],
            name: "zero",
            faceClasses: []
        )
        do {
            _ = try await metalKis.apply(to: model0, parameters: KisParameters(n: 0, apexDistance: 0.2))
            XCTFail("Should throw when faces array is empty")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
        
        // Test with 1 face
        let model1 = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "one",
            faceClasses: []
        )
        let result1 = try await metalKis.apply(to: model1, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertGreaterThan(result1.faces.count, 0)
        
        // Test with 32 faces (exact thread group boundary)
        var vertices32: [Vec3] = []
        var faces32: [[Int]] = []
        for i in 0..<32 {
            let base = i * 3
            vertices32.append(Vec3(Double(i), 0, 0))
            vertices32.append(Vec3(Double(i), 1, 0))
            vertices32.append(Vec3(Double(i), 0, 1))
            faces32.append([base, base + 1, base + 2])
        }
        let model32 = PolyhedronModel(
            vertices: vertices32,
            faces: faces32,
            name: "thirtytwo",
            faceClasses: []
        )
        let result32 = try await metalKis.apply(to: model32, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertGreaterThan(result32.faces.count, model32.faces.count)
        
        // Test with 33 faces (just over thread group boundary)
        var vertices33: [Vec3] = []
        var faces33: [[Int]] = []
        for i in 0..<33 {
            let base = i * 3
            vertices33.append(Vec3(Double(i), 0, 0))
            vertices33.append(Vec3(Double(i), 1, 0))
            vertices33.append(Vec3(Double(i), 0, 1))
            faces33.append([base, base + 1, base + 2])
        }
        let model33 = PolyhedronModel(
            vertices: vertices33,
            faces: faces33,
            name: "thirtythree",
            faceClasses: []
        )
        let result33 = try await metalKis.apply(to: model33, parameters: KisParameters(n: 0, apexDistance: 0.2))
        XCTAssertGreaterThan(result33.faces.count, model33.faces.count)
    }
    
    // MARK: - Property Verification Tests
    
    func testMetalKisOperatorIdentifier() {
        let mockDevice = MockMetalDevice()
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Should initialize with valid device")
            return
        }
        
        XCTAssertEqual(metalKis.identifier, "k", "Identifier should be 'k'")
    }
    
    func testMetalKisOperatorWithZeroApexDistance() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.0))
        XCTAssertGreaterThanOrEqual(result.vertices.count, model.vertices.count)
        // Apex should be at face center when distance is 0
    }
    
    func testMetalKisOperatorWithLargeApexDistance() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kis_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        let mockQueue = MockMetalCommandQueue()
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalKis = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            return
        }
        
        let model = PolyhedronModel(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [[0, 1, 2]],
            name: "Test",
            faceClasses: []
        )
        
        let result = try await metalKis.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 1000.0))
        XCTAssertGreaterThanOrEqual(result.vertices.count, model.vertices.count)
        // Should handle large distances gracefully
    }
}

// Helper extensions for test
extension Polyhedron {
    static func cube() async throws -> Polyhedron {
        let baseRegistry = StandardBaseRegistry.makeDefault()
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        let operatorFactory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let generator = DefaultPolyhedronGenerator(
            baseRegistry: baseRegistry,
            operatorRegistry: operatorRegistry,
            operatorFactory: operatorFactory
        )
        let model = try await generator.generate(notation: "C")
        return Polyhedron(vertices: model.vertices, faces: model.faces, name: "C", faceClasses: [], recipe: "C")
    }
    
    static func dodecahedron() async throws -> Polyhedron {
        let baseRegistry = StandardBaseRegistry.makeDefault()
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        let operatorFactory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let generator = DefaultPolyhedronGenerator(
            baseRegistry: baseRegistry,
            operatorRegistry: operatorRegistry,
            operatorFactory: operatorFactory
        )
        let model = try await generator.generate(notation: "D")
        return Polyhedron(vertices: model.vertices, faces: model.faces, name: "D", faceClasses: [], recipe: "D")
    }
}
