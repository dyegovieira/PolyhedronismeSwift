import XCTest
@testable import PolyhedronismeSwift

final class FaceCalculatorTests: XCTestCase {
    private let calculator = DefaultFaceCalculator()
    
    func testCalculateCenters() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
            faces: [[0, 1, 2]]
        )
        
        let centers = await calculator.calculateCenters(from: model)
        XCTAssertEqual(centers.count, 1)
        let center = centers[0]
        XCTAssertEqual(center[0], 1.0/3.0, accuracy: 1e-10)
        XCTAssertEqual(center[1], 1.0/3.0, accuracy: 1e-10)
        XCTAssertEqual(center[2], 0.0, accuracy: 1e-10)
    }
    
    func testCalculateCentersWithEmptyFace() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0]],
            faces: [[]]
        )
        
        let centers = await calculator.calculateCenters(from: model)
        XCTAssertEqual(centers.count, 1)
        XCTAssertEqual(centers[0], Vec3.zero())
    }
    
    func testCalculateCentersWithSmallFace() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0]],
            faces: [[0, 1]]
        )
        
        let centers = await calculator.calculateCenters(from: model)
        XCTAssertEqual(centers.count, 1)
        XCTAssertEqual(centers[0], Vec3.zero())
    }
    
    func testCalculateCentersWithOutOfBoundsIndex() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0]],
            faces: [[0, 1, 2]]
        )
        
        let centers = await calculator.calculateCenters(from: model)
        XCTAssertEqual(centers.count, 1)
        let center = centers[0]
        XCTAssertEqual(center.count, 3)
        XCTAssertTrue(center.allSatisfy { $0.isFinite })
    }
    
    func testCalculateNormals() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
            faces: [[0, 1, 2]]
        )
        
        let normals = await calculator.calculateNormals(from: model)
        XCTAssertEqual(normals.count, 1)
        let normal = normals[0]
        XCTAssertEqual(normal.count, 3)
        let magnitude = Vector3.magnitude(normal)
        XCTAssertEqual(magnitude, 1.0, accuracy: 1e-10)
    }
    
    func testCalculateNormalsWithEmptyFace() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0]],
            faces: [[]]
        )
        
        let normals = await calculator.calculateNormals(from: model)
        XCTAssertEqual(normals.count, 1)
        XCTAssertEqual(normals[0], Vec3.zero())
    }
    
    func testCalculateNormalsWithMultipleFaces() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0]
            ],
            faces: [[0, 1, 2], [0, 1, 3]]
        )
        
        let normals = await calculator.calculateNormals(from: model)
        XCTAssertEqual(normals.count, 2)
        for normal in normals {
            XCTAssertEqual(normal.count, 3)
            XCTAssertTrue(normal.allSatisfy { $0.isFinite })
        }
    }
}

