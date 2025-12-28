import XCTest
@testable import PolyhedronismeSwift

final class ReflectOperatorTests: XCTestCase {
    private let op = ReflectOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "r")
    }
    
    func testApplyReflectsVertices() async throws {
        let model = PolyhedronModel(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        let result = try await op.apply(to: model)
        
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        XCTAssertEqual(result.vertices[0], [-1.0, -2.0, -3.0])
        XCTAssertTrue(result.name.hasPrefix("r"))
    }
    
    func testApplyReversesFaces() async throws {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        let result = try await op.apply(to: model)
        
        XCTAssertEqual(result.faces[0], [2, 1, 0])
    }
}

