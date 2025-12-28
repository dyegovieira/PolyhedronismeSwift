import XCTest
@testable import PolyhedronismeSwift

final class PolyFlagTests: XCTestCase {
    func testNewV() {
        var flag = PolyFlag()
        flag.newV("v1", [1.0, 2.0, 3.0])
        
        let poly = flag.topoly()
        XCTAssertFalse(poly.vertices.isEmpty)
        XCTAssertEqual(poly.vertices[0], [1.0, 2.0, 3.0])
    }
    
    func testNewVDoesNotOverwrite() {
        var flag = PolyFlag()
        flag.newV("v1", [1.0, 2.0, 3.0])
        flag.newV("v1", [4.0, 5.0, 6.0])
        
        let poly = flag.topoly()
        XCTAssertEqual(poly.vertices[0], [1.0, 2.0, 3.0])
    }
    
    func testNewFlag() {
        var flag = PolyFlag()
        flag.newV("v1", [1.0, 0.0, 0.0])
        flag.newV("v2", [0.0, 1.0, 0.0])
        flag.newV("v3", [0.0, 0.0, 1.0])
        flag.newFlag("face1", "v1", "v2")
        flag.newFlag("face1", "v2", "v3")
        flag.newFlag("face1", "v3", "v1")
        
        let poly = flag.topoly()
        XCTAssertFalse(poly.faces.isEmpty)
    }
    
    func testTopoly() {
        var flag = PolyFlag()
        flag.newV("v1", [1.0, 0.0, 0.0])
        flag.newV("v2", [0.0, 1.0, 0.0])
        flag.newV("v3", [0.0, 0.0, 1.0])
        flag.newFlag("face1", "v1", "v2")
        flag.newFlag("face1", "v2", "v3")
        flag.newFlag("face1", "v3", "v1")
        
        let poly = flag.topoly()
        XCTAssertEqual(poly.vertices.count, 3)
        XCTAssertFalse(poly.faces.isEmpty)
        XCTAssertEqual(poly.name, "unknown polyhedron")
    }
    
    func testTopolyWithIncompleteFace() {
        var flag = PolyFlag()
        flag.newV("v1", [1.0, 0.0, 0.0])
        flag.newV("v2", [0.0, 1.0, 0.0])
        flag.newFlag("face1", "v1", "v2")
        
        let poly = flag.topoly()
        XCTAssertTrue(poly.faces.isEmpty)
    }
}

