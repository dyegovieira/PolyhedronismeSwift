import Foundation
import XCTest
@testable import PolyhedronismeSwift

final class DualOperatorTests: XCTestCase {
    private let op = DualOperator()
    
    func testIdentifier() {
        XCTAssertEqual(op.identifier, "d")
    }
    
    func testApplyToTetrahedron() async throws {
        let tetrahedron = try await TetrahedronGenerator().generate()
        let result = try await op.apply(to: tetrahedron)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
    }
    
    func testApplyToCube() async throws {
        let cube = try await CubeGenerator().generate()
        let result = try await op.apply(to: cube)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testNamePrefix() async throws {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        let result = try await op.apply(to: model)
        XCTAssertEqual(result.name, "dTest")
    }
    
    func testNameWithExistingD() async throws {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "dTest"
        )
        let result = try await op.apply(to: model)
        XCTAssertEqual(result.name, "Test")
    }
    
    func testApplyPerformanceOnKisTrisubModel() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let polyhedron = try await generator.generate(recipe: "kdu10I")
        let model = PolyhedronModel(
            vertices: polyhedron.vertices,
            faces: polyhedron.faces,
            name: polyhedron.name,
            faceClasses: polyhedron.faceClasses
        )
        let clock = ContinuousClock()
        let duration = try await clock.measure {
            _ = try await op.apply(to: model)
        }
        XCTAssertLessThan(duration, .seconds(2), "DualOperator regression: took \(duration) on kdu10I")
    }
    
    func testApplyWithComplexModel() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let polyhedron = try await generator.generate(recipe: "kI")
        let model = PolyhedronModel(
            vertices: polyhedron.vertices,
            faces: polyhedron.faces,
            name: polyhedron.name,
            faceClasses: polyhedron.faceClasses
        )
        let result = try await op.apply(to: model)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertTrue(result.vertices.allSatisfy { $0.count == 3 })
        XCTAssertTrue(result.faces.allSatisfy { !$0.isEmpty && $0.count >= 3 })
    }
}

