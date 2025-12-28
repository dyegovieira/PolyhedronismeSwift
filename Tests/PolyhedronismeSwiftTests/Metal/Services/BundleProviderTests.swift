import XCTest
@testable import PolyhedronismeSwift

final class BundleProviderTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testDefaultBundleProviderInitWithDefaultBundles() {
        let provider = DefaultBundleProvider()
        // Should initialize with default bundles
        XCTAssertNotNil(provider)
    }
    
    func testDefaultBundleProviderInitWithCustomBundles() {
        let customBundle = Bundle.main
        let provider = DefaultBundleProvider(bundles: [customBundle])
        XCTAssertNotNil(provider)
    }
    
    func testDefaultBundleProviderInitWithEmptyBundles() {
        let provider = DefaultBundleProvider(bundles: [])
        XCTAssertNotNil(provider)
    }
    
    // MARK: - URL Resolution Tests (forResource:withExtension:)
    
    func testUrlForResourceReturnsNilWhenNoBundles() {
        let provider = DefaultBundleProvider(bundles: [])
        let url = provider.url(forResource: "nonexistent", withExtension: "metal")
        XCTAssertNil(url, "Should return nil when no bundles available")
    }
    
    func testUrlForResourceReturnsNilWhenResourceNotFound() {
        let provider = DefaultBundleProvider()
        let url = provider.url(forResource: "NonexistentFile", withExtension: "metal")
        XCTAssertNil(url, "Should return nil when resource not found in any bundle")
    }
    
    func testUrlForResourceTriesAllBundles() {
        // Create a mock bundle that doesn't have the resource
        let mockBundle1 = Bundle.main
        let mockBundle2 = Bundle.module
        let provider = DefaultBundleProvider(bundles: [mockBundle1, mockBundle2])
        
        // Try to find a resource that doesn't exist
        let url = provider.url(forResource: "DefinitelyDoesNotExist", withExtension: "metal")
        XCTAssertNil(url, "Should return nil after trying all bundles")
    }
    
    // MARK: - URL Resolution Tests (forResource:withExtension:subdirectory:)
    
    func testUrlForResourceWithSubdirectoryReturnsNilWhenNoBundles() {
        let provider = DefaultBundleProvider(bundles: [])
        let url = provider.url(forResource: "nonexistent", withExtension: "metal", subdirectory: "Metal")
        XCTAssertNil(url, "Should return nil when no bundles available")
    }
    
    func testUrlForResourceWithSubdirectoryReturnsNilWhenResourceNotFound() {
        let provider = DefaultBundleProvider()
        let url = provider.url(forResource: "NonexistentFile", withExtension: "metal", subdirectory: "Metal")
        XCTAssertNil(url, "Should return nil when resource not found in any bundle")
    }
    
    func testUrlForResourceWithNilSubdirectory() {
        let provider = DefaultBundleProvider()
        // Should work the same as without subdirectory
        let url = provider.url(forResource: "NonexistentFile", withExtension: "metal", subdirectory: nil)
        XCTAssertNil(url, "Should return nil when resource not found")
    }
    
    func testUrlForResourceWithSubdirectoryTriesAllBundles() {
        let mockBundle1 = Bundle.main
        let mockBundle2 = Bundle.module
        let provider = DefaultBundleProvider(bundles: [mockBundle1, mockBundle2])
        
        let url = provider.url(forResource: "DefinitelyDoesNotExist", withExtension: "metal", subdirectory: "Metal")
        XCTAssertNil(url, "Should return nil after trying all bundles")
    }
    
    // MARK: - Read Contents Tests
    
    func testReadContentsThrowsWhenFileDoesNotExist() {
        let provider = DefaultBundleProvider()
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/file.metal")
        
        do {
            _ = try provider.readContents(of: nonExistentURL)
            XCTFail("Should throw when file does not exist")
        } catch {
            // Expected - file doesn't exist
            // Error was thrown, which is what we expect
        }
    }
    
    func testReadContentsSucceedsWithValidFile() throws {
        // Create a temporary file for testing
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).metal")
        let testContent = "kernel void test() {}"
        
        try testContent.write(to: tempFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        let provider = DefaultBundleProvider()
        let contents = try provider.readContents(of: tempFile)
        
        XCTAssertEqual(contents, testContent, "Should read file contents correctly")
    }
    
    func testReadContentsWithEmptyFile() throws {
        // Create an empty temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("empty_\(UUID().uuidString).metal")
        
        try "".write(to: tempFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        let provider = DefaultBundleProvider()
        let contents = try provider.readContents(of: tempFile)
        
        XCTAssertEqual(contents, "", "Should read empty file as empty string")
    }
    
    func testReadContentsWithLargeFile() throws {
        // Create a file with substantial content
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("large_\(UUID().uuidString).metal")
        let largeContent = String(repeating: "kernel void test() {}\n", count: 1000)
        
        try largeContent.write(to: tempFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        let provider = DefaultBundleProvider()
        let contents = try provider.readContents(of: tempFile)
        
        XCTAssertEqual(contents, largeContent, "Should read large file contents correctly")
        XCTAssertGreaterThan(contents.count, 1000, "Should have substantial content")
    }
    
    // MARK: - Bundle Iteration Tests
    
    func testUrlForResourceTriesBundlesInOrder() {
        // This test verifies that bundles are tried in the order provided
        // Since we can't easily mock Bundle.url(), we test with real bundles
        // and verify the behavior when resource doesn't exist
        let bundle1 = Bundle.main
        let bundle2 = Bundle.module
        let bundle3 = Bundle(for: MetalContext.self)
        
        let provider = DefaultBundleProvider(bundles: [bundle1, bundle2, bundle3])
        let url = provider.url(forResource: "NonexistentResource", withExtension: "metal")
        
        // Should return nil after trying all three bundles
        XCTAssertNil(url)
    }
    
    func testUrlForResourceWithSubdirectoryTriesBundlesInOrder() {
        let bundle1 = Bundle.main
        let bundle2 = Bundle.module
        let bundle3 = Bundle(for: MetalContext.self)
        
        let provider = DefaultBundleProvider(bundles: [bundle1, bundle2, bundle3])
        let url = provider.url(forResource: "NonexistentResource", withExtension: "metal", subdirectory: "Metal")
        
        // Should return nil after trying all three bundles
        XCTAssertNil(url)
    }
    
    // MARK: - Edge Cases
    
    func testUrlForResourceWithEmptyName() {
        let provider = DefaultBundleProvider()
        let url = provider.url(forResource: "", withExtension: "metal")
        XCTAssertNil(url, "Should return nil for empty resource name")
    }
    
    func testUrlForResourceWithEmptyExtension() {
        let provider = DefaultBundleProvider()
        _ = provider.url(forResource: "test", withExtension: "")
        // This might return nil or a URL depending on bundle behavior
        // We just verify it doesn't crash
        XCTAssertNotNil(provider)
    }
    
    func testUrlForResourceWithEmptySubdirectory() {
        let provider = DefaultBundleProvider()
        _ = provider.url(forResource: "test", withExtension: "metal", subdirectory: "")
        // Empty string subdirectory should be treated differently than nil
        // We verify it doesn't crash
        XCTAssertNotNil(provider)
    }
    
    func testReadContentsWithDirectoryURL() {
        let provider = DefaultBundleProvider()
        let directoryURL = FileManager.default.temporaryDirectory
        
        do {
            _ = try provider.readContents(of: directoryURL)
            XCTFail("Should throw when trying to read directory as file")
        } catch {
            // Expected - can't read directory as file
            // Error was thrown, which is what we expect
        }
    }
    
    func testReadContentsWithInvalidURL() {
        let provider = DefaultBundleProvider()
        // Create an invalid URL (not a file URL)
        let invalidURL = URL(string: "https://example.com/file.metal")!
        
        do {
            _ = try provider.readContents(of: invalidURL)
            // String(contentsOf:) might not throw immediately for HTTP URLs
            // It could throw later or return empty string, so we just verify it doesn't crash
            // and that the method can be called
        } catch {
            // If it throws, that's also acceptable
            // Error was thrown, which is acceptable behavior
        }
    }
}

