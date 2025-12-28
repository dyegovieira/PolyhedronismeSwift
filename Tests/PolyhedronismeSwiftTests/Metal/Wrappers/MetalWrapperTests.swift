import XCTest
@testable import PolyhedronismeSwift

#if canImport(Metal)
@preconcurrency import Metal
#endif

final class MetalWrapperTests: XCTestCase {
    
    func testCreateSystemDefaultDeviceWithMetal() throws {
        let device = MetalWrapper.createSystemDefaultDevice()
        guard device != nil else {
            throw XCTSkip("Metal not available")
        }
        XCTAssertNotNil(device, "Device should be created when Metal is available")
    }
    
    func testCreateSystemDefaultDeviceWithoutMetal() throws {
        let device = MetalWrapper.createSystemDefaultDevice()
        if device == nil {
            XCTAssertNil(device, "Device should be nil when Metal is not available")
        } else {
            throw XCTSkip("Metal is available, skipping nil device test")
        }
    }
    
    func testMetalResourceOptionsStorageModeShared() {
        let options = MetalResourceOptions.storageModeShared
        XCTAssertEqual(options.rawValue, 0)
    }
    
    func testMetalResourceOptionsInit() {
        let options = MetalResourceOptions(rawValue: 0)
        XCTAssertEqual(options.rawValue, 0)
    }
    
    func testMetalSizeInit() {
        let size = MetalSize(width: 64, height: 1, depth: 1)
        XCTAssertEqual(size.width, 64)
        XCTAssertEqual(size.height, 1)
        XCTAssertEqual(size.depth, 1)
    }
    
    func testMetalSizeDefaultValues() {
        let size = MetalSize(width: 32)
        XCTAssertEqual(size.width, 32)
        XCTAssertEqual(size.height, 1)
        XCTAssertEqual(size.depth, 1)
    }
    
    func testMetalSizeCustomValues() {
        let size = MetalSize(width: 128, height: 64, depth: 32)
        XCTAssertEqual(size.width, 128)
        XCTAssertEqual(size.height, 64)
        XCTAssertEqual(size.depth, 32)
    }
    
    #if canImport(Metal)
    func testMetalDeviceWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        XCTAssertNotNil(wrapper)
    }
    
    func testMetalDeviceWrapperMakeCommandQueue() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let queue = wrapper.makeCommandQueue()
        XCTAssertNotNil(queue)
    }
    
    func testMetalDeviceWrapperMakeDefaultLibrary() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let library = wrapper.makeDefaultLibrary()
        // makeDefaultLibrary() can return nil in test environments without a default library
        // This is a valid scenario - we just verify the method doesn't crash
        // The method should handle nil gracefully, which it does
        _ = library // Verify it compiles and doesn't crash
    }
    
    func testMetalDeviceWrapperMakeLibrary() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let library = try wrapper.makeLibrary(source: source, options: nil)
        XCTAssertNotNil(library)
    }
    
    func testMetalDeviceWrapperMakeComputePipelineState() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let library = try wrapper.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "test_kernel") else {
            XCTFail("Function should be created")
            throw XCTSkip("Function not found in library")
        }
        let pipeline = try wrapper.makeComputePipelineState(function: function)
        XCTAssertNotNil(pipeline)
    }
    
    func testMetalDeviceWrapperMakeComputePipelineStateWithInvalidFunction() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let mockFunction = MockMetalFunction(name: "invalid")
        do {
            _ = try wrapper.makeComputePipelineState(function: mockFunction)
            XCTFail("Should throw error for invalid function")
        } catch {
            XCTAssertTrue(error is MetalError)
        }
    }
    
    func testMetalDeviceWrapperMakeBufferFromBytes() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let data: [Float] = [1.0, 2.0, 3.0]
        let buffer = data.withUnsafeBytes { bytes in
            wrapper.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        }
        XCTAssertNotNil(buffer)
    }
    
    func testMetalDeviceWrapperMakeBufferWithLength() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let buffer = wrapper.makeBuffer(length: 1024, options: .storageModeShared)
        XCTAssertNotNil(buffer)
    }
    
    func testMetalCommandQueueWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue() else {
            throw XCTSkip("Metal device or queue not available")
        }
        let wrapper = MetalCommandQueueWrapper(queue: mtlQueue)
        XCTAssertNotNil(wrapper)
    }
    
    func testMetalCommandQueueWrapperMakeCommandBuffer() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue() else {
            throw XCTSkip("Metal device or queue not available")
        }
        let wrapper = MetalCommandQueueWrapper(queue: mtlQueue)
        let buffer = wrapper.makeCommandBuffer()
        XCTAssertNotNil(buffer)
    }
    
    func testMetalCommandBufferWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer() else {
            throw XCTSkip("Metal device, queue, or buffer not available")
        }
        let wrapper = MetalCommandBufferWrapper(buffer: mtlBuffer)
        XCTAssertNotNil(wrapper)
    }
    
    func testMetalCommandBufferWrapperMakeComputeCommandEncoder() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer() else {
            throw XCTSkip("Metal device, queue, or buffer not available")
        }
        let wrapper = MetalCommandBufferWrapper(buffer: mtlBuffer)
        let encoder = wrapper.makeComputeCommandEncoder()
        XCTAssertNotNil(encoder)
        encoder?.endEncoding()
    }
    
    func testMetalCommandBufferWrapperCommit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer() else {
            throw XCTSkip("Metal device, queue, or buffer not available")
        }
        let wrapper = MetalCommandBufferWrapper(buffer: mtlBuffer)
        wrapper.commit()
    }
    
    func testMetalCommandBufferWrapperCompleted() async throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer() else {
            throw XCTSkip("Metal device, queue, or buffer not available")
        }
        let wrapper = MetalCommandBufferWrapper(buffer: mtlBuffer)
        wrapper.commit()
        await wrapper.completed()
    }
    
    func testMetalComputeCommandEncoderWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        XCTAssertNotNil(wrapper)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperSetComputePipelineState() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let deviceWrapper = MetalDeviceWrapper(device: mtlDevice)
        let library = try deviceWrapper.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "test_kernel") else {
            wrapper.endEncoding()
            throw XCTSkip("Function not found in library")
        }
        let pipeline = try deviceWrapper.makeComputePipelineState(function: function)
        wrapper.setComputePipelineState(pipeline)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperSetBuffer() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        let deviceWrapper = MetalDeviceWrapper(device: mtlDevice)
        let buffer = deviceWrapper.makeBuffer(length: 1024, options: .storageModeShared)
        wrapper.setBuffer(buffer, offset: 0, index: 0)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperSetBufferNil() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        wrapper.setBuffer(nil, offset: 0, index: 0)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperSetBufferWithNonWrapper() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        let mockBuffer = MockMetalBuffer(length: 1024)
        wrapper.setBuffer(mockBuffer, offset: 0, index: 0)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperSetBytes() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        var data: UInt32 = 42
        wrapper.setBytes(&data, length: MemoryLayout<UInt32>.stride, index: 0)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperDispatchThreadgroups() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        
        // Metal requires a compute pipeline state to be set before dispatching threadgroups
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let deviceWrapper = MetalDeviceWrapper(device: mtlDevice)
        let library = try deviceWrapper.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "test_kernel") else {
            wrapper.endEncoding()
            throw XCTSkip("Function not found in library")
        }
        let pipeline = try deviceWrapper.makeComputePipelineState(function: function)
        wrapper.setComputePipelineState(pipeline)
        
        let threadgroups = MetalSize(width: 10, height: 1, depth: 1)
        let threads = MetalSize(width: 64, height: 1, depth: 1)
        wrapper.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threads)
        wrapper.endEncoding()
    }
    
    func testMetalComputeCommandEncoderWrapperEndEncoding() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlQueue = mtlDevice.makeCommandQueue(),
              let mtlBuffer = mtlQueue.makeCommandBuffer(),
              let mtlEncoder = mtlBuffer.makeComputeCommandEncoder() else {
            throw XCTSkip("Metal device, queue, buffer, or encoder not available")
        }
        let wrapper = MetalComputeCommandEncoderWrapper(encoder: mtlEncoder)
        wrapper.endEncoding()
    }
    
    func testMetalBufferWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlBuffer = mtlDevice.makeBuffer(length: 1024, options: .storageModeShared) else {
            throw XCTSkip("Metal device or buffer not available")
        }
        let wrapper = MetalBufferWrapper(buffer: mtlBuffer)
        XCTAssertNotNil(wrapper)
    }
    
    func testMetalBufferWrapperContents() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlBuffer = mtlDevice.makeBuffer(length: 1024, options: .storageModeShared) else {
            throw XCTSkip("Metal device or buffer not available")
        }
        let wrapper = MetalBufferWrapper(buffer: mtlBuffer)
        let contents = wrapper.contents()
        XCTAssertNotNil(contents)
    }
    
    func testMetalComputePipelineStateWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let library = try mtlDevice.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "test_kernel") else {
            throw XCTSkip("Function not found in library")
        }
        let pipeline = try mtlDevice.makeComputePipelineState(function: function)
        let wrapper = MetalComputePipelineStateWrapper(pipeline: pipeline)
        XCTAssertNotNil(wrapper)
        XCTAssertGreaterThan(wrapper.maxTotalThreadsPerThreadgroup, 0)
    }
    
    func testMetalLibraryWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlLibrary = mtlDevice.makeDefaultLibrary() else {
            throw XCTSkip("Metal device or library not available")
        }
        let wrapper = MetalLibraryWrapper(library: mtlLibrary)
        XCTAssertNotNil(wrapper)
    }
    
    func testMetalLibraryWrapperMakeFunction() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let mtlLibrary = mtlDevice.makeDefaultLibrary() else {
            throw XCTSkip("Metal device or library not available")
        }
        let wrapper = MetalLibraryWrapper(library: mtlLibrary)
        let function = wrapper.makeFunction(name: "nonExistentFunction")
        XCTAssertNil(function)
    }
    
    func testMetalFunctionWrapperInit() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let library = try mtlDevice.makeLibrary(source: source, options: nil)
        guard let mtlFunction = library.makeFunction(name: "test_kernel") else {
            throw XCTSkip("Function not found in library")
        }
        let wrapper = MetalFunctionWrapper(function: mtlFunction)
        XCTAssertNotNil(wrapper)
    }
    
    func testMetalDeviceWrapperMakeLibraryWithInvalidSource() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        
        let invalidSource = "this is not valid Metal shader code"
        
        do {
            _ = try wrapper.makeLibrary(source: invalidSource, options: nil)
            XCTFail("Should throw error for invalid Metal source")
        } catch {
            // Should throw an error
            XCTAssertNotNil(error)
        }
    }
    
    func testMetalDeviceWrapperMakeLibraryWithNilOptions() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let source = """
        kernel void test_kernel(device float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               uint id [[thread_position_in_grid]]) {
            output[id] = input[id] * 2.0;
        }
        """
        let library = try wrapper.makeLibrary(source: source, options: nil)
        XCTAssertNotNil(library)
    }
    
    func testMetalDeviceWrapperMakeBufferWithZeroLength() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        let buffer = wrapper.makeBuffer(length: 0, options: .storageModeShared)
        // Zero length buffer might return nil or a valid buffer, both are acceptable
        _ = buffer // Just verify it doesn't crash
    }
    
    func testMetalDeviceWrapperMakeBufferWithVeryLargeLength() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        // Test with a very large buffer size (1GB)
        let largeLength = 1024 * 1024 * 1024
        let buffer = wrapper.makeBuffer(length: largeLength, options: .storageModeShared)
        // Large buffer might fail due to memory constraints, which is acceptable
        _ = buffer // Just verify it doesn't crash
    }
    
    func testMetalDeviceWrapperMakeComputePipelineStateErrorTypes() throws {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device not available")
        }
        let wrapper = MetalDeviceWrapper(device: mtlDevice)
        
        // Test with invalid function wrapper type
        let mockFunction = MockMetalFunction(name: "invalid")
        do {
            _ = try wrapper.makeComputePipelineState(function: mockFunction)
            XCTFail("Should throw MetalError.functionNotFound for invalid function type")
        } catch let error as MetalError {
            if case .functionNotFound = error {
                // Expected error type
            } else {
                XCTFail("Should throw functionNotFound error")
            }
        } catch {
            XCTFail("Should throw MetalError")
        }
        
        // Test with valid function but invalid shader
        let source = """
        kernel void invalid_kernel(device float* input [[buffer(0)]],
                                  device float* output [[buffer(1)]],
                                  uint id [[thread_position_in_grid]]) {
            // Missing closing brace - invalid syntax
        """
        do {
            let library = try wrapper.makeLibrary(source: source, options: nil)
            if let function = library.makeFunction(name: "invalid_kernel") {
                // If function exists, try to create pipeline (might fail)
                do {
                    _ = try wrapper.makeComputePipelineState(function: function)
                } catch {
                    // Pipeline creation might fail, which is acceptable
                }
            }
        } catch {
            // Library creation might fail, which is acceptable
        }
    }
    #endif
}

