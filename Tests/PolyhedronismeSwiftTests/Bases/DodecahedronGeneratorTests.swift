import XCTest
@testable import PolyhedronismeSwift

final class DodecahedronGeneratorTests: XCTestCase {
    private let generator = DodecahedronGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "D")
    }
    
    func testGenerate() async throws {
        let result = try await generator.generate()
        
        XCTAssertEqual(result.vertices.count, 20)
        XCTAssertEqual(result.faces.count, 12)
        XCTAssertEqual(result.name, "D")
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        for face in result.faces {
            XCTAssertEqual(face.count, 5)
        }
    }
}

