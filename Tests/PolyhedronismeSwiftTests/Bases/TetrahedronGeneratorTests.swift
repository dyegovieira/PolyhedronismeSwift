import XCTest
@testable import PolyhedronismeSwift

final class TetrahedronGeneratorTests: XCTestCase {
    private let generator = TetrahedronGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "T")
    }
    
    func testGenerate() async throws {
        let result = try await generator.generate()
        
        XCTAssertEqual(result.vertices.count, 4)
        XCTAssertEqual(result.faces.count, 4)
        XCTAssertEqual(result.name, "T")
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        for face in result.faces {
            XCTAssertEqual(face.count, 3)
        }
    }
}

