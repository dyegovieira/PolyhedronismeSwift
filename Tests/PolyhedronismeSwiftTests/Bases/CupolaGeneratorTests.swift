import XCTest
@testable import PolyhedronismeSwift

final class CupolaGeneratorTests: XCTestCase {
    private let generator = CupolaGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "U")
    }
    
    func testGenerateWithN3() async throws {
        let params = CupolaParameters(n: 3)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
    }
    
    func testGenerateWithN5() async throws {
        let params = CupolaParameters(n: 5)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
}

