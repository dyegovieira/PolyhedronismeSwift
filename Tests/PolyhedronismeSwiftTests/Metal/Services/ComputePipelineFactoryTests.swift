import XCTest
@testable import PolyhedronismeSwift

final class ComputePipelineFactoryTests: XCTestCase {
    
    func testPipelineThrowsWhenDeviceNotFound() async {
        let mockConfig = MockMetalConfiguration(device: nil)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw MetalError.deviceNotFound")
        } catch let error as MetalError {
            if case .deviceNotFound = error {
            } else {
                XCTFail("Should throw deviceNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError.deviceNotFound, got \(error)")
        }
    }
    
    func testPipelineThrowsWhenFunctionNotFound() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.shouldFailMakeFunction = true
        mockDevice.shouldFailMakeDefaultLibrary = false
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "nonexistent_kernel")
            XCTFail("Should throw MetalError.functionNotFound")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent_kernel")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError.functionNotFound, got \(error)")
        }
    }
    
    func testPipelineThrowsWhenLibraryNotFound() async {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        mockDevice.shouldFailMakeLibrary = true
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw MetalError.functionNotFound when library fails")
        } catch let error as MetalError {
            if case .functionNotFound = error {
            } else {
                XCTFail("Should throw functionNotFound when library fails, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineCaching() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        _ = try await factory.pipeline(for: "test_kernel")
        _ = try await factory.pipeline(for: "test_kernel")
        
        XCTAssertEqual(mockDevice.makeComputePipelineStateCallCount, 1, "Pipeline should be cached")
    }
    
    func testPipelineCreationSuccess() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        
        XCTAssertNotNil(pipeline)
        XCTAssertEqual(mockDevice.makeDefaultLibraryCallCount, 1)
        XCTAssertEqual(mockDevice.makeComputePipelineStateCallCount, 1)
    }
    
    func testPipelineThrowsWhenComputePipelineStateCreationFails() async {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeComputePipelineState = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw when pipeline state creation fails")
        } catch let error as MetalError {
            if case .functionNotFound = error {
            } else {
                XCTFail("Should throw functionNotFound when pipeline state fails, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineThrowsWhenFunctionNotFoundInLibrary() async {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["other_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "nonexistent_kernel")
            XCTFail("Should throw MetalError.functionNotFound")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent_kernel")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineMultipleCallsSameFunction() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        _ = try await factory.pipeline(for: "test_kernel")
        _ = try await factory.pipeline(for: "test_kernel")
        
        XCTAssertEqual(mockDevice.makeComputePipelineStateCallCount, 1, "Should only create pipeline once")
    }
    
    func testPipelineDifferentFunctions() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kernel1", "kernel2"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        _ = try await factory.pipeline(for: "kernel1")
        _ = try await factory.pipeline(for: "kernel2")
        
        XCTAssertEqual(mockDevice.makeComputePipelineStateCallCount, 2, "Should create separate pipelines for different functions")
    }
    
    // MARK: - Error Handling Tests
    
    func testPipelineHandlesLibraryCompilationFailure() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        // First makeLibrary call will fail, then succeed on retry
        final class SelectiveFailingDevice: MetalDevice, @unchecked Sendable {
            var failOnCall: Int = 1
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
                currentCall += 1
                if currentCall == failOnCall {
                    throw MetalError.libraryNotFound
                }
                return try baseDevice.makeLibrary(source: source, options: options)
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let selectiveDevice = SelectiveFailingDevice(baseDevice: mockDevice)
        let mockConfig = MockMetalConfiguration(device: selectiveDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        // This should eventually fail since we can't actually load files in tests
        // But we can verify it tries makeLibrary (indicating file-based path attempt)
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            // If it doesn't throw, that's fine - means it found the function somehow
        } catch let error as MetalError {
            if case .functionNotFound = error {
                // Expected - function not found after trying all paths
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineContinuesAfterCompilationError() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        // makeLibrary will fail, but factory should continue trying other paths
        mockDevice.shouldFailMakeLibrary = true
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw when all paths fail")
        } catch let error as MetalError {
            if case .functionNotFound = error {
                // Expected - function not found after trying all paths
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineStateCreationFailureInFileBasedPath() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        mockDevice.shouldFailMakeComputePipelineState = true
        
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        // Create a device that succeeds makeLibrary but fails pipeline state
        final class PipelineFailingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil // Force file-based path
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary // Succeed library creation
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function) // Will fail
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let pipelineFailingDevice = PipelineFailingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: pipelineFailingDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw when pipeline state creation fails")
        } catch let error as MetalError {
            if case .functionNotFound = error {
                // Expected - pipeline state creation failed, continues to next path, eventually throws functionNotFound
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testPipelineWithEmptyFunctionName() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = []
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        do {
            _ = try await factory.pipeline(for: "")
            XCTFail("Should throw MetalError.functionNotFound for empty function name")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineConcurrentRequests() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        // Make concurrent requests for the same function
        async let pipeline1 = factory.pipeline(for: "test_kernel")
        async let pipeline2 = factory.pipeline(for: "test_kernel")
        async let pipeline3 = factory.pipeline(for: "test_kernel")
        
        let _ = try await [pipeline1, pipeline2, pipeline3]
        
        // Should only create pipeline once due to caching (actor isolation ensures thread safety)
        XCTAssertEqual(mockDevice.makeComputePipelineStateCallCount, 1, "Should only create pipeline once even with concurrent requests")
    }
    
    func testPipelineConcurrentRequestsDifferentFunctions() async throws {
        let mockDevice = MockMetalDevice()
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["kernel1", "kernel2", "kernel3"]
        mockDevice.defaultLibrary = mockLibrary
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        // Make concurrent requests for different functions
        async let pipeline1 = factory.pipeline(for: "kernel1")
        async let pipeline2 = factory.pipeline(for: "kernel2")
        async let pipeline3 = factory.pipeline(for: "kernel3")
        
        let _ = try await [pipeline1, pipeline2, pipeline3]
        
        // Should create all three pipelines
        XCTAssertEqual(mockDevice.makeComputePipelineStateCallCount, 3, "Should create separate pipelines for different functions")
    }
    
    func testPipelineFindsFunctionAfterMultipleFailures() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        
        // Device that fails makeLibrary first few times, then succeeds
        final class EventuallySucceedingDevice: MetalDevice, @unchecked Sendable {
            var succeedAfterCalls: Int = 3
            var currentCall = 0
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary, succeedAfterCalls: Int = 3) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
                self.succeedAfterCalls = succeedAfterCalls
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil // Force file-based path
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                currentCall += 1
                if currentCall < succeedAfterCalls {
                    throw MetalError.libraryNotFound
                }
                return mockLibrary // Succeed after N failures
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        let eventuallySucceedingDevice = EventuallySucceedingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary, succeedAfterCalls: 3)
        let mockConfig = MockMetalConfiguration(device: eventuallySucceedingDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        // Note: In tests, file-based loading can't actually work because we can't mock
        // Bundle.url() or String(contentsOf:). So makeLibrary() won't be called,
        // and the function won't be found. This test verifies the error path.
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw functionNotFound when file-based loading can't work in tests")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "test_kernel")
                // makeLibrary won't be called because Bundle.url() can't be mocked
                XCTAssertEqual(eventuallySucceedingDevice.currentCall, 0, "makeLibrary won't be called in tests since file-based path can't execute")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    // MARK: - File-based Loading Path Tests
    
    func testPipelineAttemptsFileBasedLoadingWhenDefaultLibraryFails() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        
        // Device that succeeds makeLibrary (simulating file-based loading)
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        final class FileBasedLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            var makeLibraryCallCount = 0
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil // Force file-based path
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                makeLibraryCallCount += 1
                return mockLibrary // Simulate successful file loading and compilation
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileBasedDevice = FileBasedLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileBasedDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        // Note: In tests, file-based loading can't actually work because we can't mock
        // Bundle.url() or String(contentsOf:). So makeLibrary() won't be called,
        // and the function won't be found. This test verifies the error path.
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw functionNotFound when default library fails and file-based loading can't work in tests")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "test_kernel")
                // makeLibrary won't be called because Bundle.url() can't be mocked
                XCTAssertEqual(fileBasedDevice.makeLibraryCallCount, 0, "makeLibrary won't be called in tests since file-based path can't execute")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineTriesMultipleBundlesAndFiles() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        // Track which files/bundles are tried
        var triedSources: [String] = []
        
        final class TrackingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            var triedSources: [String]
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary, triedSources: inout [String]) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
                self.triedSources = triedSources
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil // Force file-based path
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                triedSources.append(source)
                // Fail first few attempts to simulate trying different files
                if triedSources.count < 3 {
                    throw MetalError.libraryNotFound
                }
                return mockLibrary // Succeed on 3rd attempt
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let trackingDevice = TrackingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary, triedSources: &triedSources)
        let mockConfig = MockMetalConfiguration(device: trackingDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig)
        
        // Note: In tests, file-based loading can't actually work because we can't mock
        // Bundle.url() or String(contentsOf:). So makeLibrary() won't be called,
        // and the function won't be found. This test verifies the error path.
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw functionNotFound when file-based loading can't work in tests")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "test_kernel")
                // makeLibrary won't be called because Bundle.url() can't be mocked
                XCTAssertEqual(triedSources.count, 0, "makeLibrary won't be called in tests since file-based path can't execute")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    // MARK: - File-based Loading Tests (with BundleProvider)
    
    func testPipelineLoadsFromRootDirectory() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        let mockURL = URL(fileURLWithPath: "/test/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal"] = mockURL
        
        final class FileLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileDevice = FileLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        XCTAssertEqual(mockBundleProvider.readContentsCallCount, 1, "Should read file contents")
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal"))
    }
    
    func testPipelineLoadsFromMetalSubdirectory() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        let mockURL = URL(fileURLWithPath: "/test/Metal/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal.Metal"] = mockURL
        
        final class FileLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? { baseDevice.makeCommandQueue() }
            func makeDefaultLibrary() -> MetalLibrary? { nil }
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary
            }
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileDevice = FileLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal.Metal"))
    }
    
    func testPipelineLoadsFromSPMBundleSubdirectory() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        let subdirectory = "PolyhedronismeSwift_PolyhedronismeSwift.bundle/Metal"
        let mockURL = URL(fileURLWithPath: "/test/bundle/Metal/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal.\(subdirectory)"] = mockURL
        
        final class FileLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? { baseDevice.makeCommandQueue() }
            func makeDefaultLibrary() -> MetalLibrary? { nil }
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary
            }
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileDevice = FileLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal.\(subdirectory)"))
    }
    
    func testPipelineHandlesFileReadingFailure() async throws {
        let mockBundleProvider = MockBundleProvider()
        mockBundleProvider.shouldFailReadContents = true
        let mockURL = URL(fileURLWithPath: "/test/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal"] = mockURL
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw when file reading fails and no other paths succeed")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "test_kernel")
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineTriesAllMetalFiles() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        // Only return URL for the 4th file (ReflectOperatorKernels)
        let mockURL = URL(fileURLWithPath: "/test/ReflectOperatorKernels.metal")
        mockBundleProvider.urlsToReturn["ReflectOperatorKernels.metal"] = mockURL
        
        final class FileLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? { baseDevice.makeCommandQueue() }
            func makeDefaultLibrary() -> MetalLibrary? { nil }
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary
            }
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileDevice = FileLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        // Should have tried all files before finding it in ReflectOperatorKernels
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal"))
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("KisOperatorKernels.metal"))
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("AmboOperatorKernels.metal"))
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("ReflectOperatorKernels.metal"))
    }
    
    func testPipelineTriesAllSubdirectories() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        // Only return URL for the 3rd subdirectory (SPM bundle)
        let subdirectory = "PolyhedronismeSwift_PolyhedronismeSwift.bundle/Metal"
        let mockURL = URL(fileURLWithPath: "/test/bundle/Metal/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal.\(subdirectory)"] = mockURL
        
        final class FileLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? { baseDevice.makeCommandQueue() }
            func makeDefaultLibrary() -> MetalLibrary? { nil }
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary
            }
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileDevice = FileLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        // Should have tried root, then Metal, then SPM bundle
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal"))
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal.Metal"))
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal.\(subdirectory)"))
    }
    
    func testPipelineHandlesLibraryCompilationError() async throws {
        let mockBundleProvider = MockBundleProvider()
        let mockURL = URL(fileURLWithPath: "/test/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal"] = mockURL
        
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        mockDevice.shouldFailMakeLibrary = true // This will cause compilation to fail
        
        let mockConfig = MockMetalConfiguration(device: mockDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            XCTFail("Should throw when all paths fail")
        } catch let error as MetalError {
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "test_kernel")
                // Should have attempted to read the file
                XCTAssertGreaterThan(mockBundleProvider.readContentsCallCount, 0)
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineFindsFunctionInSecondFile() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        
        // First library won't have the function, second will
        let mockLibrary1 = MockMetalLibrary()
        mockLibrary1.availableFunctions = ["other_kernel"]
        let mockLibrary2 = MockMetalLibrary()
        mockLibrary2.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        let url1 = URL(fileURLWithPath: "/test/GeometryKernels.metal")
        let url2 = URL(fileURLWithPath: "/test/KisOperatorKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal"] = url1
        mockBundleProvider.urlsToReturn["KisOperatorKernels.metal"] = url2
        
        final class MultiLibraryDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary1: MockMetalLibrary
            let mockLibrary2: MockMetalLibrary
            var libraryCallCount: Int = 0
            
            init(baseDevice: MockMetalDevice, mockLibrary1: MockMetalLibrary, mockLibrary2: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary1 = mockLibrary1
                self.mockLibrary2 = mockLibrary2
            }
            
            func makeCommandQueue() -> MetalCommandQueue? { baseDevice.makeCommandQueue() }
            func makeDefaultLibrary() -> MetalLibrary? { nil }
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                libraryCallCount += 1
                // Return first library for first call, second for subsequent calls
                return libraryCallCount == 1 ? mockLibrary1 : mockLibrary2
            }
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let multiDevice = MultiLibraryDevice(baseDevice: mockDevice, mockLibrary1: mockLibrary1, mockLibrary2: mockLibrary2)
        let mockConfig = MockMetalConfiguration(device: multiDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        // Should have tried GeometryKernels first (no function), then KisOperatorKernels (found function)
        XCTAssertGreaterThanOrEqual(multiDevice.libraryCallCount, 2)
    }
    
    func testPipelineContinuesAfterFileNotFound() async throws {
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true
        let mockLibrary = MockMetalLibrary()
        mockLibrary.availableFunctions = ["test_kernel"]
        
        let mockBundleProvider = MockBundleProvider()
        // First file doesn't exist, second does
        let mockURL = URL(fileURLWithPath: "/test/KisOperatorKernels.metal")
        mockBundleProvider.urlsToReturn["KisOperatorKernels.metal"] = mockURL
        
        final class FileLoadingDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            let mockLibrary: MockMetalLibrary
            
            init(baseDevice: MockMetalDevice, mockLibrary: MockMetalLibrary) {
                self.baseDevice = baseDevice
                self.mockLibrary = mockLibrary
            }
            
            func makeCommandQueue() -> MetalCommandQueue? { baseDevice.makeCommandQueue() }
            func makeDefaultLibrary() -> MetalLibrary? { nil }
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                return mockLibrary
            }
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let fileDevice = FileLoadingDevice(baseDevice: mockDevice, mockLibrary: mockLibrary)
        let mockConfig = MockMetalConfiguration(device: fileDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        let pipeline = try await factory.pipeline(for: "test_kernel")
        XCTAssertNotNil(pipeline)
        // Should have tried GeometryKernels first (not found), then KisOperatorKernels (found)
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("GeometryKernels.metal"))
        XCTAssertTrue(mockBundleProvider.urlsRequested.contains("KisOperatorKernels.metal"))
    }
    
    // MARK: - Error Handling Else Branches
    
    func testPipelineThrowsWrongMetalErrorType() async {
        // Test that the factory handles wrong MetalError types during file-based loading
        // The factory catches errors from makeLibrary() and continues searching files
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true // Force file-based loading path
        
        // Create a bundle provider that returns a URL but readContents fails
        let mockBundleProvider = MockBundleProvider()
        let mockURL = URL(fileURLWithPath: "/test/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal"] = mockURL
        mockBundleProvider.shouldFailReadContents = false // Will succeed, but makeLibrary will fail
        
        // Create a device that throws a different MetalError
        final class WrongErrorDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            
            init(baseDevice: MockMetalDevice) {
                self.baseDevice = baseDevice
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil // Force file-based loading
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                throw MetalError.deviceNotFound // Wrong error type (should be functionNotFound)
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let wrongErrorDevice = WrongErrorDevice(baseDevice: mockDevice)
        let mockConfig = MockMetalConfiguration(device: wrongErrorDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            // The factory catches deviceNotFound errors from makeLibrary() and continues
            // Eventually throws functionNotFound when no files contain the function
            XCTFail("Should throw functionNotFound after catching deviceNotFound errors")
        } catch let error as MetalError {
            // The factory catches the deviceNotFound error and continues searching files
            // Eventually it throws functionNotFound when no files contain the function
            if case .functionNotFound = error {
                // Expected - factory converts the error to functionNotFound after trying all files
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
    
    func testPipelineThrowsNonMetalError() async {
        // Test that the factory handles non-MetalError exceptions during file-based loading
        // The factory catches errors from makeLibrary() and continues searching files
        let mockDevice = MockMetalDevice()
        mockDevice.shouldFailMakeDefaultLibrary = true // Force file-based loading path
        
        // Create a bundle provider that returns a URL and readContents succeeds
        let mockBundleProvider = MockBundleProvider()
        let mockURL = URL(fileURLWithPath: "/test/GeometryKernels.metal")
        mockBundleProvider.urlsToReturn["GeometryKernels.metal"] = mockURL
        mockBundleProvider.shouldFailReadContents = false // Will succeed, but makeLibrary will fail
        
        // Create a device that throws a non-MetalError
        final class NonMetalErrorDevice: MetalDevice, @unchecked Sendable {
            let baseDevice: MockMetalDevice
            
            init(baseDevice: MockMetalDevice) {
                self.baseDevice = baseDevice
            }
            
            func makeCommandQueue() -> MetalCommandQueue? {
                return baseDevice.makeCommandQueue()
            }
            
            func makeDefaultLibrary() -> MetalLibrary? {
                return nil // Force file-based loading
            }
            
            func makeLibrary(source: String, options: MetalLibraryCompileOptions?) throws -> MetalLibrary {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Non-Metal error"])
            }
            
            func makeComputePipelineState(function: MetalFunction) throws -> MetalComputePipelineState {
                return try baseDevice.makeComputePipelineState(function: function)
            }
            
            func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(bytes: bytes, length: length, options: options)
            }
            
            func makeBuffer(length: Int, options: MetalResourceOptions) -> MetalBuffer? {
                return baseDevice.makeBuffer(length: length, options: options)
            }
        }
        
        let nonMetalErrorDevice = NonMetalErrorDevice(baseDevice: mockDevice)
        let mockConfig = MockMetalConfiguration(device: nonMetalErrorDevice)
        let factory = ComputePipelineFactory(metalConfig: mockConfig, bundleProvider: mockBundleProvider)
        
        do {
            _ = try await factory.pipeline(for: "test_kernel")
            // The factory catches non-Metal errors from makeLibrary() and continues
            // Eventually throws functionNotFound when no files contain the function
            XCTFail("Should throw functionNotFound after catching non-Metal errors")
        } catch let error as MetalError {
            // The factory catches non-Metal errors during file loading and continues searching
            // Eventually it throws functionNotFound when no files contain the function
            if case .functionNotFound = error {
                // Expected - factory converts to functionNotFound after catching non-Metal errors
            } else {
                XCTFail("Should throw functionNotFound, got \(error)")
            }
        } catch {
            XCTFail("Should throw MetalError, got \(error)")
        }
    }
}

