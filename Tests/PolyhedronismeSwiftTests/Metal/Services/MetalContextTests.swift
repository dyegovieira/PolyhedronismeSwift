import XCTest
@testable import PolyhedronismeSwift

final class MetalContextTests: XCTestCase {
    
    func testInitWithNilDevice() throws {
        let context = MetalContext()
        
        guard context.device == nil else {
            throw XCTSkip("Metal device is available, skipping nil device test")
        }
        XCTAssertNil(context.commandQueue, "Command queue should be nil when device is nil")
    }
    
    func testInitWithValidDevice() throws {
        let context = MetalContext()
        
        guard let device = context.device else {
            throw XCTSkip("Metal device not available")
        }
        XCTAssertNotNil(device, "Device should exist")
        XCTAssertNotNil(context.commandQueue, "Command queue should exist when device exists")
    }
    
    func testMakeBufferWithEmptyArray() {
        let context = MetalContext()
        let buffer = context.makeBuffer(array: [Int](), options: .storageModeShared)
        
        XCTAssertNil(buffer, "Empty array should return nil buffer")
    }
    
    func testMakeBufferWithValidArrayWhenDeviceExists() throws {
        let context = MetalContext()
        let array = [1, 2, 3, 4, 5]
        
        guard context.device != nil else {
            throw XCTSkip("Metal device not available")
        }
        let buffer = context.makeBuffer(array: array, options: .storageModeShared)
        XCTAssertNotNil(buffer, "Valid array should create buffer when device exists")
    }
    
    func testMakeBufferWithValidArrayWhenDeviceNil() throws {
        let context = MetalContext()
        let array = [1, 2, 3, 4, 5]
        
        guard context.device == nil else {
            throw XCTSkip("Metal device is available, skipping nil device test")
        }
        let buffer = context.makeBuffer(array: array, options: .storageModeShared)
        XCTAssertNil(buffer, "Buffer should be nil when device is nil")
    }
    
    func testMakeBufferWithDifferentTypes() throws {
        let context = MetalContext()
        
        guard context.device != nil else {
            throw XCTSkip("Metal device not available")
        }
        let intBuffer = context.makeBuffer(array: [1, 2, 3], options: .storageModeShared)
        XCTAssertNotNil(intBuffer)
        
        let doubleBuffer = context.makeBuffer(array: [1.0, 2.0, 3.0], options: .storageModeShared)
        XCTAssertNotNil(doubleBuffer)
        
        let floatBuffer = context.makeBuffer(array: [Float(1.0), Float(2.0)], options: .storageModeShared)
        XCTAssertNotNil(floatBuffer)
    }
    
    func testMakeBufferWithNilDevice() {
        let mockConfig = MockMetalConfiguration(device: nil)
        let buffer = mockConfig.makeBuffer(array: [1, 2, 3], options: .storageModeShared)
        
        XCTAssertNil(buffer, "Buffer should be nil when device is nil")
    }
    
    func testMetalContextConformsToMetalConfiguration() {
        let context = MetalContext()
        let config: MetalConfiguration = context
        XCTAssertNotNil(config)
    }
}

