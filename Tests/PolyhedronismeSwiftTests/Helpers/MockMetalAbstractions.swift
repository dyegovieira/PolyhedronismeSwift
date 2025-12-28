import Foundation
@testable import PolyhedronismeSwift

final class MockMetalDevice: MetalDevice, @unchecked Sendable {
    var shouldFailMakeCommandQueue = false
    var shouldFailMakeDefaultLibrary = false
    var shouldFailMakeLibrary = false
    var shouldFailMakeBuffer = false
    var shouldFailMakeComputePipelineState = false
    
    var makeCommandQueueCallCount = 0
    var makeDefaultLibraryCallCount = 0
    var makeLibraryCallCount = 0
    var makeBufferCallCount = 0
    var makeComputePipelineStateCallCount = 0
    
    var defaultLibrary: MockMetalLibrary?
    
    func makeCommandQueue() -> MetalCommandQueue? {
        makeCommandQueueCallCount += 1
        if shouldFailMakeCommandQueue {
            return nil
        }
        return MockMetalCommandQueue()
    }
    
    func makeDefaultLibrary() -> MetalLibrary? {
        makeDefaultLibraryCallCount += 1
        if shouldFailMakeDefaultLibrary {
            return nil
        }
        if let library = defaultLibrary {
            return library
        }
        return MockMetalLibrary()
    }
    
    func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
        makeLibraryCallCount += 1
        if shouldFailMakeLibrary {
            throw MetalError.libraryNotFound
        }
        return MockMetalLibrary()
    }
    
    func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
        makeComputePipelineStateCallCount += 1
        if shouldFailMakeComputePipelineState {
            throw MetalError.functionNotFound("mock")
        }
        return MockMetalComputePipelineState()
    }
    
    func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
        makeBufferCallCount += 1
        if shouldFailMakeBuffer {
            return nil
        }
        return MockMetalBuffer(length: length)
    }
    
    func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
        makeBufferCallCount += 1
        if shouldFailMakeBuffer {
            return nil
        }
        return MockMetalBuffer(length: length)
    }
}

final class MockMetalCommandQueue: MetalCommandQueue, @unchecked Sendable {
    var shouldFailMakeCommandBuffer = false
    var makeCommandBufferCallCount = 0
    
    func makeCommandBuffer() -> MetalCommandBuffer? {
        makeCommandBufferCallCount += 1
        if shouldFailMakeCommandBuffer {
            return nil
        }
        return MockMetalCommandBuffer()
    }
}

final class MockMetalCommandBuffer: MetalCommandBuffer, @unchecked Sendable {
    var shouldFailMakeComputeCommandEncoder = false
    var makeComputeCommandEncoderCallCount = 0
    var commitCallCount = 0
    var completedCallCount = 0
    
    func makeComputeCommandEncoder() -> MetalComputeCommandEncoder? {
        makeComputeCommandEncoderCallCount += 1
        if shouldFailMakeComputeCommandEncoder {
            return nil
        }
        return MockMetalComputeCommandEncoder()
    }
    
    func commit() {
        commitCallCount += 1
    }
    
    func completed() async {
        completedCallCount += 1
    }
}

final class MockMetalComputeCommandEncoder: MetalComputeCommandEncoder, @unchecked Sendable {
    var setComputePipelineStateCallCount = 0
    var setBufferCallCount = 0
    var setBytesCallCount = 0
    var dispatchThreadgroupsCallCount = 0
    var endEncodingCallCount = 0
    
    var lastPipelineState: MetalComputePipelineState?
    var lastBuffers: [(buffer: MetalBuffer?, offset: Int, index: Int)] = []
    var lastBytes: [(length: Int, index: Int)] = []
    var lastThreadgroups: [(threadgroupsPerGrid: MetalSize, threadsPerThreadgroup: MetalSize)] = []
    
    func setComputePipelineState(_ state: MetalComputePipelineState) {
        setComputePipelineStateCallCount += 1
        lastPipelineState = state
    }
    
    func setBuffer(_ buffer: MetalBuffer?, offset: Int, index: Int) {
        setBufferCallCount += 1
        lastBuffers.append((buffer: buffer, offset: offset, index: index))
    }
    
    func setBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        setBytesCallCount += 1
        lastBytes.append((length: length, index: index))
    }
    
    func dispatchThreadgroups(_ threadgroupsPerGrid: MetalSize, threadsPerThreadgroup: MetalSize) {
        dispatchThreadgroupsCallCount += 1
        lastThreadgroups.append((threadgroupsPerGrid: threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup))
    }
    
    func endEncoding() {
        endEncodingCallCount += 1
    }
}

final class MockMetalBuffer: MetalBuffer, @unchecked Sendable {
    private let data: UnsafeMutableRawPointer
    let length: Int
    
    init(length: Int) {
        self.length = length
        self.data = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 1)
    }
    
    deinit {
        data.deallocate()
    }
    
    func contents() -> UnsafeMutableRawPointer {
        data
    }
}

final class MockMetalComputePipelineState: MetalComputePipelineState, @unchecked Sendable {
    var maxTotalThreadsPerThreadgroup: Int
    
    init(maxTotalThreadsPerThreadgroup: Int = 64) {
        self.maxTotalThreadsPerThreadgroup = maxTotalThreadsPerThreadgroup
    }
}

final class MockMetalLibrary: MetalLibrary, @unchecked Sendable {
    var shouldFailMakeFunction = false
    var makeFunctionCallCount = 0
    var availableFunctions: [String] = []
    
    func makeFunction(name: String) -> MetalFunction? {
        makeFunctionCallCount += 1
        if shouldFailMakeFunction || !availableFunctions.contains(name) {
            return nil
        }
        return MockMetalFunction(name: name)
    }
}

final class MockMetalFunction: MetalFunction, Sendable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

final class MockMetalConfiguration: MetalConfiguration, @unchecked Sendable {
    let device: MetalDevice?
    let commandQueue: MetalCommandQueue?
    
    init(device: MetalDevice? = nil, commandQueue: MetalCommandQueue? = nil) {
        self.device = device
        self.commandQueue = commandQueue
    }
    
    func makeBuffer<T>(array: [T], options: MetalResourceOptions) -> MetalBuffer? {
        guard let device = device, !array.isEmpty else { return nil }
        return array.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: buffer.count, options: options)
        }
    }
}

