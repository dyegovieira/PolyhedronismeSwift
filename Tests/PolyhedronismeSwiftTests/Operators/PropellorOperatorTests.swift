import XCTest
@testable import PolyhedronismeSwift

final class PropellorOperatorTests: XCTestCase {
    private let op = PropellorOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "p")
    }
    
    func testApplyToTetrahedron() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let result = try await op.apply(to: tetrahedron)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("p"))
    }
}

