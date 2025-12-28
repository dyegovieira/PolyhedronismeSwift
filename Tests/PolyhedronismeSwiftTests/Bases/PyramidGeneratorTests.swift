import XCTest
@testable import PolyhedronismeSwift

final class PyramidGeneratorTests: XCTestCase {
    private let generator = PyramidGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "Y")
    }
    
    func testGenerateWithN3() async throws {
        let params = PyramidParameters(n: 3)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
    }
    
    func testGenerateWithN5() async throws {
        let params = PyramidParameters(n: 5)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
}

