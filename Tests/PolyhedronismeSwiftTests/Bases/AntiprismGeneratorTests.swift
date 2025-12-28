import XCTest
@testable import PolyhedronismeSwift

final class AntiprismGeneratorTests: XCTestCase {
    private let generator = AntiprismGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "A")
    }
    
    func testGenerateWithN3() async throws {
        let params = AntiprismParameters(n: 3)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
    }
    
    func testGenerateWithN6() async throws {
        let params = AntiprismParameters(n: 6)
        let result = try await generator.generate(parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
}

