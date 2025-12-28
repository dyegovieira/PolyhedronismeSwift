import XCTest
@testable import PolyhedronismeSwift

final class OBJExporterTests: XCTestCase {
    private let exporter = OBJExporter()
    
    func testExportBasicPolyhedron() async throws {
        let model = PolyhedronModel(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let objString = try await exporter.export(model)
        
        XCTAssertFalse(objString.isEmpty)
        XCTAssertTrue(objString.contains("Test"))
        XCTAssertTrue(objString.contains("vertices"))
        XCTAssertTrue(objString.contains("face defs"))
        XCTAssertTrue(objString.contains("v 1.0 2.0 3.0"))
    }
    
    func testExportWithMultipleVertices() async throws {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0]
            ],
            faces: [[0, 1, 2], [0, 1, 3]],
            name: "Tetrahedron"
        )
        
        let objString = try await exporter.export(model)
        
        XCTAssertTrue(objString.contains("v 0.0 0.0 0.0"))
        XCTAssertTrue(objString.contains("v 1.0 0.0 0.0"))
        XCTAssertTrue(objString.contains("v 0.0 1.0 0.0"))
        XCTAssertTrue(objString.contains("v 0.0 0.0 1.0"))
    }
    
    func testExportWithMultipleFaces() async throws {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
            faces: [[0, 1, 2], [0, 2, 1]],
            name: "Double Face"
        )
        
        let objString = try await exporter.export(model)
        
        let faceCount = objString.components(separatedBy: "f ").count - 1
        XCTAssertEqual(faceCount, 2)
    }
    
    func testExportIncludesNormalVectors() async throws {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
            faces: [[0, 1, 2]],
            name: "Triangle"
        )
        
        let objString = try await exporter.export(model)
        
        XCTAssertTrue(objString.contains("vn"), "Should include normal vector definitions")
    }
    
    func testExportWithEmptyModel() async throws {
        let model = PolyhedronModel(name: "Empty")
        let objString = try await exporter.export(model)
        
        XCTAssertFalse(objString.isEmpty)
        XCTAssertTrue(objString.contains("Empty"))
    }
}

