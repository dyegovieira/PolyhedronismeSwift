import XCTest
@testable import PolyhedronismeSwift

final class DefaultOperatorFactoryTests: XCTestCase {
    
    func testCreateKisOperator() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "k", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateKisOperatorWithParameters() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let params = [SendableParameter.int(5), SendableParameter.double(0.3)]
        let operation = OperatorOperation(identifier: "k", parameters: params)
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateReflectOperator() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "r", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateDualOperator() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "d", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateAmboOperator() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "a", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateTrisubOperator() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let params = [SendableParameter.int(3)]
        let operation = OperatorOperation(identifier: "u", parameters: params)
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateTrisubOperatorWithDefaultParameter() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "u", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateGenericOperator() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "g", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op)
    }
    
    func testCreateGenericOperatorThrowsWhenNotFound() async {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: MockMetalDevice())
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "nonexistent", parameters: [])
        
        do {
            _ = try await factory.createOperator(for: operation)
            XCTFail("Should throw when operator not found")
        } catch let error as GenerationError {
            if case .parsingFailed(let parseError) = error {
                if case .unknownOperator(let id) = parseError {
                    XCTAssertEqual(id, "nonexistent")
                } else {
                    XCTFail("Should throw unknownOperator error")
                }
            } else {
                XCTFail("Should throw parsingFailed error")
            }
        } catch {
            XCTFail("Should throw GenerationError, got \(error)")
        }
    }
    
    func testCreateOperatorWithNilMetalDevice() async throws {
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        let metalConfig = MockMetalConfiguration(device: nil)
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        
        let factory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        let operation = OperatorOperation(identifier: "d", parameters: [])
        let op = try await factory.createOperator(for: operation)
        
        XCTAssertNotNil(op, "Should fallback to CPU operator when Metal unavailable")
    }
}

