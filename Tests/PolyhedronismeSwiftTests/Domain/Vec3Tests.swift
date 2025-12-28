import XCTest
@testable import PolyhedronismeSwift

final class Vec3Tests: XCTestCase {
    func testZero() {
        let zero = Vec3.zero()
        XCTAssertEqual(zero, [0.0, 0.0, 0.0])
    }
    
    func testXYZAccessors() {
        var vec: Vec3 = [1.0, 2.0, 3.0]
        XCTAssertEqual(vec.x, 1.0)
        XCTAssertEqual(vec.y, 2.0)
        XCTAssertEqual(vec.z, 3.0)
        
        vec.x = 4.0
        vec.y = 5.0
        vec.z = 6.0
        XCTAssertEqual(vec, [4.0, 5.0, 6.0])
    }
    
    func testInitializer() {
        let vec = Vec3(1.0, 2.0, 3.0)
        XCTAssertEqual(vec, [1.0, 2.0, 3.0])
    }
    
    func testIsValidWithValidVec3() {
        let vec: Vec3 = [1.0, 2.0, 3.0]
        XCTAssertTrue(vec.isValid())
    }
    
    func testComponentCountIsAlwaysThree() {
        let vec: Vec3 = [1.0, 2.0, 3.0]
        XCTAssertEqual(vec.count, 3)
    }
    
    func testIsValidWithNonFiniteValues() {
        let vec1: Vec3 = [1.0, 2.0, Double.infinity]
        XCTAssertFalse(vec1.isValid(), "Vec3 with infinity should be invalid")
        
        let vec2: Vec3 = [1.0, 2.0, Double.nan]
        XCTAssertFalse(vec2.isValid(), "Vec3 with NaN should be invalid")
    }
    
    func testIsValidWithFiniteValues() {
        let vec: Vec3 = [1.0, -2.0, 0.0]
        XCTAssertTrue(vec.isValid(), "Vec3 with finite values should be valid")
    }
    
    func testInitFromArray() {
        let vec = Vec3([1.0, 2.0, 3.0])
        XCTAssertEqual(vec, [1.0, 2.0, 3.0])
    }
    
    func testAllSatisfy() {
        let vec: Vec3 = [1.0, 2.0, 3.0]
        
        XCTAssertTrue(vec.allSatisfy { $0 > 0 })
        XCTAssertFalse(vec.allSatisfy { $0 > 2 })
        XCTAssertTrue(vec.allSatisfy { $0.isFinite })
    }
    
    func testArrayProperty() {
        let vec: Vec3 = [1.5, 2.5, 3.5]
        let array = vec.array
        
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0], 1.5)
        XCTAssertEqual(array[1], 2.5)
        XCTAssertEqual(array[2], 3.5)
    }
}

