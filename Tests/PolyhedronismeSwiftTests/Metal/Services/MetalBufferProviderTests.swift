import XCTest
@testable import PolyhedronismeSwift

final class MetalBufferProviderTests: XCTestCase {
    
    func testInitReturnsNilWhenDeviceIsNil() {
        let provider = MetalBufferProvider(device: nil)
        XCTAssertNil(provider)
    }
    
    func testInitSucceedsWhenDeviceExists() {
        let mockDevice = MockMetalDevice()
        let provider = MetalBufferProvider(device: mockDevice)
        XCTAssertNotNil(provider)
    }
    
    func testMakeBufferFromArrayReturnsNilForEmptyArray() {
        let mockDevice = MockMetalDevice()
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let buffer = provider.makeBuffer(from: [Int]())
        XCTAssertNil(buffer, "Empty array should return nil buffer")
    }
    
    func testMakeBufferFromArraySucceeds() {
        let mockDevice = MockMetalDevice()
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let array = [1, 2, 3, 4, 5]
        let buffer = provider.makeBuffer(from: array)
        
        XCTAssertNotNil(buffer)
        XCTAssertEqual(mockDevice.makeBufferCallCount, 1)
    }
    
    func testMakeBufferFromArrayReturnsNilWhenDeviceFails() {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let array = [1, 2, 3]
        let buffer = provider.makeBuffer(from: array)
        
        XCTAssertNil(buffer)
        XCTAssertEqual(mockDevice.makeBufferCallCount, 1)
    }
    
    func testMakeBufferWithLengthSucceeds() {
        let mockDevice = MockMetalDevice()
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let buffer = provider.makeBuffer(length: 1024)
        
        XCTAssertNotNil(buffer)
        XCTAssertEqual(mockDevice.makeBufferCallCount, 1)
    }
    
    func testMakeBufferWithLengthReturnsNilWhenDeviceFails() {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeBuffer = true
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let buffer = provider.makeBuffer(length: 1024)
        
        XCTAssertNil(buffer)
        XCTAssertEqual(mockDevice.makeBufferCallCount, 1)
    }
    
    func testMakeBufferUsesDefaultOptions() {
        let mockDevice = MockMetalDevice()
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let array = [1.0, 2.0, 3.0]
        _ = provider.makeBuffer(from: array)
        
        XCTAssertEqual(mockDevice.makeBufferCallCount, 1)
    }
    
    func testMakeBufferWithCustomOptions() {
        let mockDevice = MockMetalDevice()
        let provider = MetalBufferProvider(device: mockDevice)!
        
        let array = [1.0, 2.0, 3.0]
        _ = provider.makeBuffer(from: array, options: .storageModeShared)
        
        XCTAssertEqual(mockDevice.makeBufferCallCount, 1)
    }
}

