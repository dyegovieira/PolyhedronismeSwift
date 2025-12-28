import XCTest
@testable import PolyhedronismeSwift

final class CubeGeneratorTests: XCTestCase {
    private let generator = CubeGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "C")
    }
    
    func testGenerate() async throws {
        let result = try await generator.generate()
        
        XCTAssertEqual(result.vertices.count, 8)
        XCTAssertEqual(result.faces.count, 6)
        XCTAssertEqual(result.name, "C")
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        for face in result.faces {
            XCTAssertEqual(face.count, 4)
        }
    }
}

