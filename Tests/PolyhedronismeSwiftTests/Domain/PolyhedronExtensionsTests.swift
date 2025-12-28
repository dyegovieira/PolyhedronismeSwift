import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronExtensionsTests: XCTestCase {
    func testPolyhedronInitFromModel() {
        let model = PolyhedronModel(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
            faces: [[0, 1, 2]],
            name: "Test Model",
            faceClasses: [1, 2]
        )
        
        let polyhedron = Polyhedron(model)
        
        XCTAssertEqual(polyhedron.vertices, model.vertices)
        XCTAssertEqual(polyhedron.faces, model.faces)
        XCTAssertEqual(polyhedron.name, model.name)
        XCTAssertEqual(polyhedron.faceClasses, model.faceClasses)
    }
    
    func testPolyhedronModelInitFromPolyhedron() {
        var polyhedron = Polyhedron(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
            faces: [[0, 1, 2]],
            name: "Test Polyhedron"
        )
        polyhedron.faceClasses = [1, 2, 3]
        
        let model = PolyhedronModel(polyhedron)
        
        XCTAssertEqual(model.vertices, polyhedron.vertices)
        XCTAssertEqual(model.faces, polyhedron.faces)
        XCTAssertEqual(model.name, polyhedron.name)
        XCTAssertEqual(model.faceClasses, polyhedron.faceClasses)
    }
    
    func testRoundTripConversion() {
        let originalModel = PolyhedronModel(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
            faces: [[0, 1, 2]],
            name: "Round Trip Test",
            faceClasses: [1, 2]
        )
        
        let polyhedron = Polyhedron(originalModel)
        let convertedModel = PolyhedronModel(polyhedron)
        
        XCTAssertEqual(convertedModel.vertices, originalModel.vertices)
        XCTAssertEqual(convertedModel.faces, originalModel.faces)
        XCTAssertEqual(convertedModel.name, originalModel.name)
        XCTAssertEqual(convertedModel.faceClasses, originalModel.faceClasses)
    }
    
    func testConversionWithEmptyModel() {
        let emptyModel = PolyhedronModel()
        let polyhedron = Polyhedron(emptyModel)
        let convertedModel = PolyhedronModel(polyhedron)
        
        XCTAssertTrue(convertedModel.isEmpty)
        XCTAssertEqual(convertedModel.name, "null polyhedron")
    }
}

