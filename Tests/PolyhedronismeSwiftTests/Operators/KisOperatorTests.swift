import XCTest
@testable import PolyhedronismeSwift

final class KisOperatorTests: XCTestCase {
    private let op = KisOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "k")
    }
    
    func testApplyWithDefaultParameters() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let params = KisParameters()
        let result = try await op.apply(to: tetrahedron, parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("k"))
    }
    
    func testApplyWithNParameter() async throws {
        let cube = try await CubeGenerator().generate()
        let params = KisParameters(n: 4, apexDistance: 0.1)
        let result = try await op.apply(to: cube, parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.contains("4"))
    }
}

