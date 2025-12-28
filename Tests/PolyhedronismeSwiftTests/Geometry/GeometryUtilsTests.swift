import XCTest
@testable import PolyhedronismeSwift

final class GeometryUtilsTests: XCTestCase {
    func testSignificantFigures() {
        let result1 = GeometryUtils.significantFigures(123.456, 3)
        XCTAssertFalse(result1.isEmpty)
        
        let result2 = GeometryUtils.significantFigures(0.00123, 2)
        XCTAssertFalse(result2.isEmpty)
        
        let result3 = GeometryUtils.significantFigures(1000.0, 1)
        XCTAssertFalse(result3.isEmpty)
    }
    
    func testCopyVecArray() {
        let original: [Vec3] = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
        let copied = GeometryUtils.copyVecArray(original)
        
        XCTAssertEqual(copied, original)
        XCTAssertNotIdentical(copied as AnyObject, original as AnyObject, "Should be a copy, not reference")
    }
    
    func testTangentPoint() {
        let v1: Vec3 = [1.0, 0.0, 0.0]
        let v2: Vec3 = [0.0, 1.0, 0.0]
        let tangent = GeometryUtils.tangentPoint(v1, v2)
        
        XCTAssertEqual(tangent.count, 3)
        XCTAssertTrue(tangent.allSatisfy { $0.isFinite })
    }
    
    func testTangentPointWithParallelVectors() {
        let v1: Vec3 = [1.0, 0.0, 0.0]
        let v2: Vec3 = [2.0, 0.0, 0.0]
        let tangent = GeometryUtils.tangentPoint(v1, v2)
        
        XCTAssertEqual(tangent, v1, "Parallel vectors should return first point")
    }
    
    func testTangentPointWithIdenticalVectors() {
        let v1: Vec3 = [1.0, 2.0, 3.0]
        let v2: Vec3 = [1.0, 2.0, 3.0]
        let tangent = GeometryUtils.tangentPoint(v1, v2)
        
        XCTAssertEqual(tangent, v1, "Identical vectors should return first point")
    }
    
    func testTangentPointWithSmallCrossProduct() {
        // Test case where cross product magnitude is very small (< 1e-20)
        // This happens when v1 and d are nearly collinear
        let v1: Vec3 = [1.0, 0.0, 0.0]
        let v2: Vec3 = [1.0 + 1e-10, 0.0, 0.0]  // Very close to v1, nearly collinear
        let tangent = GeometryUtils.tangentPoint(v1, v2)
        
        // Should return v1 when cross product is too small
        XCTAssertEqual(tangent[0], v1[0], accuracy: 1e-15)
        XCTAssertEqual(tangent[1], v1[1], accuracy: 1e-15)
        XCTAssertEqual(tangent[2], v1[2], accuracy: 1e-15)
    }
    
    func testEdgeDistance() {
        let v1: Vec3 = [1.0, 0.0, 0.0]
        let v2: Vec3 = [0.0, 1.0, 0.0]
        let distance = GeometryUtils.edgeDistance(v1, v2)
        
        XCTAssertGreaterThanOrEqual(distance, 0.0)
        XCTAssertTrue(distance.isFinite)
    }
    
    func testLinePointDistanceSquared() {
        let v1: Vec3 = [0.0, 0.0, 0.0]
        let v2: Vec3 = [1.0, 0.0, 0.0]
        let v3: Vec3 = [0.5, 1.0, 0.0]
        
        let distance2 = GeometryUtils.linePointDistanceSquared(v1, v2, v3)
        XCTAssertEqual(distance2, 1.0, accuracy: 1e-10)
    }
    
    func testLinePointDistanceSquaredBeforeSegment() {
        let v1: Vec3 = [1.0, 0.0, 0.0]
        let v2: Vec3 = [2.0, 0.0, 0.0]
        let v3: Vec3 = [0.0, 0.0, 0.0]
        
        let distance2 = GeometryUtils.linePointDistanceSquared(v1, v2, v3)
        XCTAssertEqual(distance2, 1.0, accuracy: 1e-10)
    }
    
    func testLinePointDistanceSquaredAfterSegment() {
        let v1: Vec3 = [0.0, 0.0, 0.0]
        let v2: Vec3 = [1.0, 0.0, 0.0]
        let v3: Vec3 = [2.0, 0.0, 0.0]
        
        let distance2 = GeometryUtils.linePointDistanceSquared(v1, v2, v3)
        XCTAssertEqual(distance2, 1.0, accuracy: 1e-10)
    }
    
    func testLinePointDistanceSquaredWithZeroLength() {
        let v1: Vec3 = [1.0, 2.0, 3.0]
        let v2: Vec3 = [1.0, 2.0, 3.0]
        let v3: Vec3 = [0.0, 0.0, 0.0]
        
        let distance2 = GeometryUtils.linePointDistanceSquared(v1, v2, v3)
        let expected = Vector3.magnitudeSquared(Vector3.subtract(v1, v3))
        XCTAssertEqual(distance2, expected, accuracy: 1e-10)
    }
    
    func testOrthogonal() {
        let v1: Vec3 = [0.0, 0.0, 0.0]
        let v2: Vec3 = [1.0, 0.0, 0.0]
        let v3: Vec3 = [1.0, 1.0, 0.0]
        
        let orthogonal = GeometryUtils.orthogonal(v1, v2, v3)
        XCTAssertEqual(orthogonal.count, 3)
        XCTAssertTrue(orthogonal.allSatisfy { $0.isFinite })
    }
    
    func testIntersect() {
        let set1 = [1, 2, 3]
        let set2 = [2, 3, 4]
        let set3 = [3, 4, 5]
        
        let result = GeometryUtils.intersect(set1, set2, set3)
        XCTAssertEqual(result, 3)
    }
    
    func testIntersectNoCommon() {
        let set1 = [1, 2, 3]
        let set2 = [4, 5, 6]
        let set3 = [7, 8, 9]
        
        let result = GeometryUtils.intersect(set1, set2, set3)
        XCTAssertNil(result)
    }
    
    func testCalculateCentroid() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 0.0],
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]
        
        let centroid = GeometryUtils.calculateCentroid(vertices)
        XCTAssertEqual(centroid[0], 0.25, accuracy: 1e-10)
        XCTAssertEqual(centroid[1], 0.25, accuracy: 1e-10)
        XCTAssertEqual(centroid[2], 0.25, accuracy: 1e-10)
    }
    
    func testCalculateCentroidEmpty() {
        let vertices: [Vec3] = []
        let centroid = GeometryUtils.calculateCentroid(vertices)
        XCTAssertEqual(centroid, Vec3.zero())
    }
    
    func testCalculateNormal() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 0.0],
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0]
        ]
        
        let normal = GeometryUtils.calculateNormal(vertices)
        XCTAssertEqual(normal.count, 3)
        let magnitude = Vector3.magnitude(normal)
        XCTAssertEqual(magnitude, 1.0, accuracy: 1e-10, "Normal should be normalized")
    }
    
    func testCalculateNormalWithLessThanThreeVertices() {
        let vertices1: [Vec3] = [[0.0, 0.0, 0.0]]
        let normal1 = GeometryUtils.calculateNormal(vertices1)
        XCTAssertEqual(normal1, Vec3.zero())
        
        let vertices2: [Vec3] = [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0]]
        let normal2 = GeometryUtils.calculateNormal(vertices2)
        XCTAssertEqual(normal2, Vec3.zero())
    }
    
    func testPlanarArea() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 0.0],
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0]
        ]
        
        let area = GeometryUtils.planarArea(vertices)
        XCTAssertEqual(area, 0.5, accuracy: 1e-10)
    }
    
    func testPlanarAreaWithLessThanThreeVertices() {
        let vertices1: [Vec3] = []
        XCTAssertEqual(GeometryUtils.planarArea(vertices1), 0.0)
        
        let vertices2: [Vec3] = [[0.0, 0.0, 0.0]]
        XCTAssertEqual(GeometryUtils.planarArea(vertices2), 0.0)
    }
    
    func testFaceSignature() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 0.0],
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0]
        ]
        
        let signature = GeometryUtils.faceSignature(vertices, 3)
        XCTAssertFalse(signature.isEmpty)
    }
    
    func testProject2DFace() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 1.0],
            [1.0, 0.0, 1.0],
            [0.0, 1.0, 1.0]
        ]
        
        let projected = GeometryUtils.project2DFace(vertices)
        XCTAssertEqual(projected.count, vertices.count)
        for proj in projected {
            XCTAssertEqual(proj.count, 2)
            XCTAssertTrue(proj.allSatisfy { $0.isFinite })
        }
    }
    
    func testPerspectiveTransform() {
        let vec3: Vec3 = [1.0, 2.0, 10.0]
        let result = GeometryUtils.perspectiveTransform(
            vec3,
            maxRealDepth: 20.0,
            minRealDepth: 5.0,
            desiredRatio: 0.5,
            desiredLength: 1.0
        )
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isFinite })
    }
    
    func testInversePerspectiveTransform() {
        let result = GeometryUtils.inversePerspectiveTransform(
            0.1, 0.2, 0.0, 0.0,
            maxRealDepth: 20.0,
            minRealDepth: 5.0,
            desiredRatio: 0.5,
            desiredLength: 1.0
        )
        
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { $0.isFinite })
    }
    
    func testInversePerspectiveTransformWithSmallDenominator() {
        let result = GeometryUtils.inversePerspectiveTransform(
            0.0, 0.0, 0.0, 0.0,
            maxRealDepth: 20.0,
            minRealDepth: 5.0,
            desiredRatio: 0.5,
            desiredLength: 1.0
        )
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[2], 1.0, accuracy: 1e-10, "Should return default z=1.0 when denominator is too small")
    }
    
    func testInversePerspectiveTransformEdgeCases() {
        let result1 = GeometryUtils.inversePerspectiveTransform(
            1.0, 0.0, 0.0, 0.0,
            maxRealDepth: 20.0,
            minRealDepth: 5.0,
            desiredRatio: 0.99,
            desiredLength: 1.0
        )
        
        XCTAssertEqual(result1.count, 3)
        XCTAssertTrue(result1.allSatisfy { $0.isFinite })
        
        let result2 = GeometryUtils.inversePerspectiveTransform(
            0.0, 1.0, 0.0, 0.0,
            maxRealDepth: 10.0,
            minRealDepth: 1.0,
            desiredRatio: 0.1,
            desiredLength: 0.5
        )
        
        XCTAssertEqual(result2.count, 3)
        XCTAssertTrue(result2.allSatisfy { $0.isFinite })
    }
    
    func testBackwardCompatibleWrappers() {
        let v1: Vec3 = [1.0, 0.0, 0.0]
        let v2: Vec3 = [0.0, 1.0, 0.0]
        
        let tangent1 = tangentPoint(v1, v2)
        let tangent2 = GeometryUtils.tangentPoint(v1, v2)
        XCTAssertEqual(tangent1, tangent2)
        
        let dist1 = edgeDist(v1, v2)
        let dist2 = GeometryUtils.edgeDistance(v1, v2)
        XCTAssertEqual(dist1, dist2)
        
        let v3: Vec3 = [0.5, 0.5, 0.0]
        let dist21 = linePointDist2(v1, v2, v3)
        let dist22 = GeometryUtils.linePointDistanceSquared(v1, v2, v3)
        XCTAssertEqual(dist21, dist22)
    }
}

