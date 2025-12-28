import XCTest
@testable import PolyhedronismeSwift

final class GyroOperatorTests: XCTestCase {
    private let op = GyroOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "g")
    }
    
    func testApplyToTetrahedron() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let result = try await op.apply(to: tetrahedron)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("g"))
    }
    
    func testApplyToCube() async throws {
        let cube = try await CubeGenerator().generate()
        let result = try await op.apply(to: cube)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("g"))
    }
}

