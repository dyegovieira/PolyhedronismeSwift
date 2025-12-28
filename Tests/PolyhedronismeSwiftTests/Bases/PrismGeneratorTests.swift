import XCTest
@testable import PolyhedronismeSwift

final class PrismGeneratorTests: XCTestCase {
    private let generator = PrismGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "P")
    }
    
    func testGenerateWithN3() async throws {
        let params = PrismParameters(n: 3)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
    }
    
    func testGenerateWithN6() async throws {
        let params = PrismParameters(n: 6)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
}

