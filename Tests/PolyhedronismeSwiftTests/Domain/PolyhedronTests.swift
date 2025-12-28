import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronTests: XCTestCase {
    private var polyhedron: Polyhedron?
    
    override func setUp() {
        super.setUp()
        polyhedron = Polyhedron(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]],
            faces: [[0, 1, 2]],
            name: "Test Polyhedron"
        )
    }
    
    override func tearDown() {
        polyhedron = nil
        super.tearDown()
    }
    
    func testInitializerWithParameters() throws {
        let polyhedron = try XCTUnwrap(polyhedron)
        XCTAssertEqual(polyhedron.vertices.count, 3)
        XCTAssertEqual(polyhedron.faces.count, 1)
        XCTAssertEqual(polyhedron.name, "Test Polyhedron")
    }
    
    func testInitializerWithDefaults() {
        let empty = Polyhedron()
        XCTAssertTrue(empty.vertices.isEmpty)
        XCTAssertTrue(empty.faces.isEmpty)
        XCTAssertEqual(empty.name, "null polyhedron")
    }
    
    func testProperties() throws {
        var polyhedron = try XCTUnwrap(polyhedron)
        polyhedron.name = "New Name"
        XCTAssertEqual(polyhedron.name, "New Name")
        
        polyhedron.faceClasses = [1, 2, 3]
        XCTAssertEqual(polyhedron.faceClasses, [1, 2, 3])
    }
    
    func testRecipeProperty() {
        let polyWithRecipe = Polyhedron(
            vertices: [[1.0, 2.0, 3.0]],
            faces: [[0]],
            name: "Test",
            recipe: "I"
        )
        XCTAssertEqual(polyWithRecipe.recipe, "I")
        
        let polyWithoutRecipe = Polyhedron()
        XCTAssertNil(polyWithoutRecipe.recipe)
    }
}
