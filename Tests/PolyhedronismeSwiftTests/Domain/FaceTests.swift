import XCTest
@testable import PolyhedronismeSwift

final class FaceTests: XCTestCase {
    func testIsValidWithValidFace() {
        let face: Face = [0, 1, 2]
        XCTAssertTrue(face.isValid(vertexCount: 3))
    }
    
    func testIsValidWithInvalidCount() {
        let face1: Face = [0, 1]
        XCTAssertFalse(face1.isValid(vertexCount: 3), "Face with <3 vertices should be invalid")
        
        let face2: Face = []
        XCTAssertFalse(face2.isValid(vertexCount: 3), "Empty face should be invalid")
    }
    
    func testIsValidWithOutOfBoundsIndex() {
        let face: Face = [0, 1, 5]
        XCTAssertFalse(face.isValid(vertexCount: 3), "Face with out-of-bounds index should be invalid")
    }
    
    func testIsValidWithNegativeIndex() {
        let face: Face = [0, 1, -1]
        XCTAssertFalse(face.isValid(vertexCount: 3), "Face with negative index should be invalid")
    }
    
    func testIsValidWithBoundaryIndices() {
        let face: Face = [0, 1, 2]
        XCTAssertTrue(face.isValid(vertexCount: 3), "Face with valid boundary indices should be valid")
    }
    
    func testHasDuplicatesWithNoDuplicates() {
        let face: Face = [0, 1, 2, 3]
        XCTAssertFalse(face.hasDuplicates(), "Face without duplicates should return false")
    }
    
    func testHasDuplicatesWithDuplicates() {
        let face: Face = [0, 1, 2, 1]
        XCTAssertTrue(face.hasDuplicates(), "Face with duplicates should return true")
    }
    
    func testHasDuplicatesWithAllSame() {
        let face: Face = [2, 2, 2]
        XCTAssertTrue(face.hasDuplicates(), "Face with all same vertices should have duplicates")
    }
}

