import XCTest
@testable import PolyhedronismeSwift

final class GeometryConstantsTests: XCTestCase {
    func testPi() {
        XCTAssertEqual(GeometryConstants.pi, Double.pi, accuracy: 1e-10)
    }
    
    func testLn10() {
        XCTAssertEqual(GeometryConstants.ln10, log(10.0), accuracy: 1e-10)
    }
    
    func testEpsilon() {
        XCTAssertEqual(GeometryConstants.epsilon, 1.0e-8, accuracy: 1e-10)
    }
    
    func testMaxFaceSidedness() {
        XCTAssertEqual(GeometryConstants.maxFaceSidedness, 1000)
    }
}

