import Foundation
@testable import PolyhedronismeSwift

final class MockBundleProvider: BundleProvider, @unchecked Sendable {
    var urlsToReturn: [String: URL] = [:] // Key: "fileName.subdirectory" or "fileName"
    var shouldFailReadContents = false
    var readContentsCallCount = 0
    var urlsRequested: [String] = []
    var readContentsSources: [String] = []
    
    func url(forResource name: String, withExtension ext: String) -> URL? {
        let key = "\(name).\(ext)"
        urlsRequested.append(key)
        return urlsToReturn[key]
    }
    
    func url(forResource name: String, withExtension ext: String, subdirectory: String?) -> URL? {
        let key = subdirectory.map { "\(name).\(ext).\($0)" } ?? "\(name).\(ext)"
        urlsRequested.append(key)
        return urlsToReturn[key]
    }
    
    func readContents(of url: URL) throws -> String {
        readContentsCallCount += 1
        if shouldFailReadContents {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read file"])
        }
        // Return mock Metal shader source - can be customized per test
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        kernel void test_kernel(device float3* vertices [[buffer(0)]], uint id [[thread_position_in_grid]]) {}
        """
        readContentsSources.append(source)
        return source
    }
}

