import XCTest
@testable import PolyhedronismeSwift

final class MetalOperatorErrorTests: XCTestCase {
    
    func testMetalAmboOperatorInitReturnsNilWhenDeviceIsNil() {
        let mockConfig = MockMetalConfiguration(device: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        let metalOperator = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory)
        XCTAssertNil(metalOperator)
    }
    
    func testMetalAmboOperatorThrowsWhenBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize even with failing device")
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
    
    func testMetalAmboOperatorThrowsWhenCommandBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["ambo_vertex_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockQueue = MockMetalCommandQueue()
        mockQueue.shouldFailMakeCommandBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice, commandQueue: mockQueue)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
    
    func testMetalReflectOperatorThrowsWhenBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalReflectOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
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
    
    func testMetalDualOperatorThrowsWhenBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
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
    
    func testMetalKisOperatorThrowsWhenBufferCreationFails() async throws {
        let cube = try await Polyhedron.cube()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalKisOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        do {
            _ = try await metalOperator.apply(to: model, parameters: KisParameters(n: 0, apexDistance: 0.2))
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
    
    func testMetalAmboOperatorReturnsOriginalWhenNoEdges() async throws {
        let emptyModel = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "empty",
            faceClasses: []
        )
        
        let mockDevice = MockMetalDevice()
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let pipelineFactory = ComputePipelineFactory(metalConfig: mockConfig)
        
        guard let metalOperator = MetalAmboOperator(metalConfig: mockConfig, pipelineFactory: pipelineFactory) else {
            XCTFail("Operator should initialize")
            return
        }
        
        let result = try await metalOperator.apply(to: emptyModel)
        XCTAssertEqual(result.vertices.count, 0)
        XCTAssertEqual(result.faces.count, 0)
        XCTAssertEqual(result.name, "empty", "When no edges, should return original polyhedron unchanged")
    }
}

