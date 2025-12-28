import XCTest
@testable import PolyhedronismeSwift

final class DefaultVertexCalculatorTests: XCTestCase {
    private let calculator = DefaultVertexCalculator()
    
    func testCalculateCentroid() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 0.0],
            [2.0, 0.0, 0.0],
            [0.0, 2.0, 0.0],
            [0.0, 0.0, 2.0]
        ]
        
        let centroid = calculator.calculateCentroid(of: vertices)
        
        XCTAssertEqual(centroid.count, 3)
        XCTAssertEqual(centroid[0], 0.5, accuracy: 1e-10)
        XCTAssertEqual(centroid[1], 0.5, accuracy: 1e-10)
        XCTAssertEqual(centroid[2], 0.5, accuracy: 1e-10)
    }
    
    func testCalculateCentroidWithEmptyVertices() {
        let centroid = calculator.calculateCentroid(of: [])
        XCTAssertEqual(centroid, Vec3.zero())
    }
}

