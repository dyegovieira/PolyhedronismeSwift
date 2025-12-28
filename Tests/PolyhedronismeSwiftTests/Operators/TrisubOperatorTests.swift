import XCTest
@testable import PolyhedronismeSwift

final class TrisubOperatorTests: XCTestCase {
    private let op = TrisubOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "u")
    }
    
    func testApplyWithDefaultParameters() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let params = TrisubParameters()
        let result = try await op.apply(to: tetrahedron, parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("u"))
    }
    
    func testApplyWithNParameter() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let params = TrisubParameters(n: 3)
        let result = try await op.apply(to: tetrahedron, parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.contains("3"))
    }
    
    func testApplyToNonTriangularFaces() async throws {
        let cube = try await CubeGenerator().generate()
        let params = TrisubParameters(n: 2)
        let result = try await op.apply(to: cube, parameters: params)
        
        XCTAssertEqual(result.vertices, cube.vertices)
        XCTAssertEqual(result.faces, cube.faces)
    }
    
    func testApplyWithLargeNParameter() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let params = TrisubParameters(n: 5)
        let result = try await op.apply(to: tetrahedron, parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertGreaterThan(result.vertices.count, tetrahedron.vertices.count)
    }
    
    func testApplyToIcosahedron() async throws {
        let icosahedron = try await IcosahedronGenerator().generate()
        let params = TrisubParameters(n: 3)
        let result = try await op.apply(to: icosahedron, parameters: params)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.name.hasPrefix("u"))
    }
}

