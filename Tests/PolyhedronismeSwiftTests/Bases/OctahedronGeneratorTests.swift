import XCTest
@testable import PolyhedronismeSwift

final class OctahedronGeneratorTests: XCTestCase {
    private let generator = OctahedronGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "O")
    }
    
    func testGenerate() async throws {
        let result = try await generator.generate()
        
        XCTAssertEqual(result.vertices.count, 6)
        XCTAssertEqual(result.faces.count, 8)
        XCTAssertEqual(result.name, "O")
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        for face in result.faces {
            XCTAssertEqual(face.count, 3)
        }
    }
}

