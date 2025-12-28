import XCTest
@testable import PolyhedronismeSwift

final class AmboOperatorTests: XCTestCase {
    private let op = AmboOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "a")
    }
    
    func testApplyToTetrahedron() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let result = try await op.apply(to: tetrahedron)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("a"))
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        for face in result.faces {
            XCTAssertGreaterThanOrEqual(face.count, 3)
        }
    }
    
    func testApplyToCube() async throws {
        let cube = try await CubeGenerator().generate()
        let result = try await op.apply(to: cube)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("a"))
    }
    
    func testNamePrefix() async throws {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        let result = try await op.apply(to: model)
        XCTAssertEqual(result.name, "aTest")
    }
}

