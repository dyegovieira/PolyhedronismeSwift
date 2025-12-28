import XCTest
@testable import PolyhedronismeSwift

final class Vector3Tests: XCTestCase {
    func testMultiply() {
        let vec: Vec3 = [1.0, 2.0, 3.0]
        let result = Vector3.multiply(2.0, vec)
        
        XCTAssertEqual(result, [2.0, 4.0, 6.0])
    }
    
    func testAdd() {
        let vec1: Vec3 = [1.0, 2.0, 3.0]
        let vec2: Vec3 = [4.0, 5.0, 6.0]
        let result = Vector3.add(vec1, vec2)
        
        XCTAssertEqual(result, [5.0, 7.0, 9.0])
    }
    
    func testSubtract() {
        let vec1: Vec3 = [5.0, 7.0, 9.0]
        let vec2: Vec3 = [1.0, 2.0, 3.0]
        let result = Vector3.subtract(vec1, vec2)
        
        XCTAssertEqual(result, [4.0, 5.0, 6.0])
    }
    
    func testDot() {
        let vec1: Vec3 = [1.0, 2.0, 3.0]
        let vec2: Vec3 = [4.0, 5.0, 6.0]
        let result = Vector3.dot(vec1, vec2)
        
        XCTAssertEqual(result, 32.0, accuracy: 1e-10)
    }
    
    func testCross() {
        let vec1: Vec3 = [1.0, 0.0, 0.0]
        let vec2: Vec3 = [0.0, 1.0, 0.0]
        let result = Vector3.cross(vec1, vec2)
        
        XCTAssertEqual(result[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 1.0, accuracy: 1e-10)
    }
    
    func testMagnitude() {
        let vec: Vec3 = [3.0, 4.0, 0.0]
        let result = Vector3.magnitude(vec)
        
        XCTAssertEqual(result, 5.0, accuracy: 1e-10)
    }
    
    func testNormalize() {
        let vec: Vec3 = [3.0, 4.0, 0.0]
        let result = Vector3.normalize(vec)
        
        XCTAssertEqual(Vector3.magnitude(result), 1.0, accuracy: 1e-10)
    }
    
    func testNormalizeZeroVector() {
        let vec: Vec3 = [0.0, 0.0, 0.0]
        let result = Vector3.normalize(vec)
        
        XCTAssertEqual(result, [0.0, 0.0, 0.0])
    }
    
    func testMidpoint() {
        let vec1: Vec3 = [0.0, 0.0, 0.0]
        let vec2: Vec3 = [2.0, 2.0, 2.0]
        let result = Vector3.midpoint(vec1, vec2)
        
        XCTAssertEqual(result[0], 1.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 1.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 1.0, accuracy: 1e-10)
    }
    
    func testMultiplyTwoVectors() {
        let vec1: Vec3 = [1.0, 2.0, 3.0]
        let vec2: Vec3 = [4.0, 5.0, 6.0]
        let result = Vector3.multiply(vec1, vec2)
        
        XCTAssertEqual(result, [4.0, 10.0, 18.0])
    }
    
    func testMagnitudeSquared() {
        let vec: Vec3 = [3.0, 4.0, 0.0]
        let result = Vector3.magnitudeSquared(vec)
        
        XCTAssertEqual(result, 25.0, accuracy: 1e-10)
    }
    
    func testTween() {
        let vec1: Vec3 = [0.0, 0.0, 0.0]
        let vec2: Vec3 = [10.0, 10.0, 10.0]
        
        let result0 = Vector3.tween(vec1, vec2, 0.0)
        XCTAssertEqual(result0, vec1)
        
        let result1 = Vector3.tween(vec1, vec2, 1.0)
        XCTAssertEqual(result1, vec2)
        
        let result05 = Vector3.tween(vec1, vec2, 0.5)
        XCTAssertEqual(result05[0], 5.0, accuracy: 1e-10)
        XCTAssertEqual(result05[1], 5.0, accuracy: 1e-10)
        XCTAssertEqual(result05[2], 5.0, accuracy: 1e-10)
    }
    
    func testOneThird() {
        let vec1: Vec3 = [0.0, 0.0, 0.0]
        let vec2: Vec3 = [9.0, 9.0, 9.0]
        let result = Vector3.oneThird(vec1, vec2)
        
        XCTAssertEqual(result[0], 3.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 3.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 3.0, accuracy: 1e-10)
    }
    
    func testReciprocal() {
        let vec: Vec3 = [2.0, 2.0, 2.0]
        let result = Vector3.reciprocal(vec)
        let mag2 = Vector3.magnitudeSquared(vec)
        let expected = vec / mag2
        
        XCTAssertEqual(result[0], expected[0], accuracy: 1e-10)
        XCTAssertEqual(result[1], expected[1], accuracy: 1e-10)
        XCTAssertEqual(result[2], expected[2], accuracy: 1e-10)
    }
    
    func testReciprocalZeroVector() {
        let vec: Vec3 = [0.0, 0.0, 0.0]
        let result = Vector3.reciprocal(vec)
        
        XCTAssertEqual(result, Vec3.zero())
    }
    
    func testWrapperFunctions() {
        let vec1: Vec3 = [1.0, 2.0, 3.0]
        let vec2: Vec3 = [4.0, 5.0, 6.0]
        
        let multResult = Vector3.multiply(2.0, vec1)
        XCTAssertEqual(multResult, [2.0, 4.0, 6.0])
        
        let addResult = Vector3.add(vec1, vec2)
        XCTAssertEqual(addResult, [5.0, 7.0, 9.0])
        
        let subResult = Vector3.subtract(vec1, vec2)
        XCTAssertEqual(subResult, [-3.0, -3.0, -3.0])
        
        let dotResult = Vector3.dot(vec1, vec2)
        XCTAssertEqual(dotResult, 32.0, accuracy: 1e-10)
        
        let crossResult = Vector3.cross(vec1, vec2)
        XCTAssertEqual(crossResult[0], -3.0, accuracy: 1e-10)
        XCTAssertEqual(crossResult[1], 6.0, accuracy: 1e-10)
        XCTAssertEqual(crossResult[2], -3.0, accuracy: 1e-10)
        
        let magResult = Vector3.magnitude(vec1)
        XCTAssertEqual(magResult, Vector3.magnitude(vec1), accuracy: 1e-10)
        
        let mag2Result = Vector3.magnitudeSquared(vec1)
        XCTAssertEqual(mag2Result, Vector3.magnitudeSquared(vec1), accuracy: 1e-10)
        
        let unitResult = Vector3.normalize(vec1)
        XCTAssertEqual(unitResult, Vector3.normalize(vec1))
        
        let midpointResult = Vector3.midpoint(vec1, vec2)
        XCTAssertEqual(midpointResult, Vector3.midpoint(vec1, vec2))
        
        let tweenResult = Vector3.tween(vec1, vec2, 0.5)
        XCTAssertEqual(tweenResult, Vector3.tween(vec1, vec2, 0.5))
        
        let oneThirdResult = Vector3.oneThird(vec1, vec2)
        XCTAssertEqual(oneThirdResult, Vector3.oneThird(vec1, vec2))
        
        let reciprocalResult = Vector3.reciprocal(vec1)
        XCTAssertEqual(reciprocalResult, Vector3.reciprocal(vec1))
    }
}

