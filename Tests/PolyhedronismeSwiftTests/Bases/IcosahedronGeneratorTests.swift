import XCTest
@testable import PolyhedronismeSwift

final class IcosahedronGeneratorTests: XCTestCase {
    private let generator = IcosahedronGenerator()
    
    func testIdentifier() {
        XCTAssertEqual(generator.identifier, "I")
    }
    
    func testGenerate() async throws {
        let result = try await generator.generate()
        
        XCTAssertEqual(result.vertices.count, 12)
        XCTAssertEqual(result.faces.count, 20)
        XCTAssertEqual(result.name, "I")
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        for face in result.faces {
            XCTAssertEqual(face.count, 3)
        }
    }
}

