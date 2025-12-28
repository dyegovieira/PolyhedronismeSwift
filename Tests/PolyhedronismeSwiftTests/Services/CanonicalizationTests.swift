import XCTest
@testable import PolyhedronismeSwift

final class CanonicalizationTests: XCTestCase {
    func testRecenter() {
        let vertices: [Vec3] = [
            [1.0, 1.0, 1.0],
            [2.0, 2.0, 2.0],
            [3.0, 3.0, 3.0]
        ]
        let edges: [[Int]] = [[0, 1], [1, 2]]
        
        let recentered = recenter(vertices, edges)
        
        XCTAssertEqual(recentered.count, vertices.count)
        for v in recentered {
            XCTAssertEqual(v.count, 3)
            XCTAssertTrue(v.allSatisfy { $0.isFinite })
        }
    }
    
    func testRescale() {
        let vertices: [Vec3] = [
            [10.0, 0.0, 0.0],
            [0.0, 10.0, 0.0],
            [0.0, 0.0, 10.0]
        ]
        
        let rescaled = rescale(vertices)
        
        XCTAssertEqual(rescaled.count, vertices.count)
        let maxMagnitude = rescaled.map { Vector3.magnitude($0) }.max() ?? 0.0
        XCTAssertEqual(maxMagnitude, 1.0, accuracy: 1e-10)
    }
    
    func testRescaleWithZeroVertices() {
        let vertices: [Vec3] = []
        let rescaled = rescale(vertices)
        XCTAssertTrue(rescaled.isEmpty)
    }
    
    func testTangentify() {
        let vertices: [Vec3] = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]
        let edges: [[Int]] = [[0, 1], [1, 2]]
        
        let tangentified = tangentify(vertices, edges)
        
        XCTAssertEqual(tangentified.count, vertices.count)
        for v in tangentified {
            XCTAssertEqual(v.count, 3)
            XCTAssertTrue(v.allSatisfy { $0.isFinite })
        }
    }
    
    func testPlanarize() {
        let vertices: [Vec3] = [
            [0.0, 0.0, 0.0],
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.1]
        ]
        let faces: [Face] = [[0, 1, 2]]
        
        let planarized = planarize(vertices, faces)
        
        XCTAssertEqual(planarized.count, vertices.count)
        for v in planarized {
            XCTAssertEqual(v.count, 3)
            XCTAssertTrue(v.allSatisfy { $0.isFinite })
        }
    }
    
    func testCanonicalize() async {
        let poly = Polyhedron(
            vertices: [[1.0, 1.0, 1.0], [2.0, 2.0, 2.0], [3.0, 3.0, 3.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let canonical = await canonicalize(poly, 1)
        
        XCTAssertEqual(canonical.vertices.count, poly.vertices.count)
        XCTAssertEqual(canonical.faces.count, poly.faces.count)
        XCTAssertEqual(canonical.name, poly.name)
    }
    
    func testCanonicalXYZ() async {
        let canonicalizer = DefaultPolyhedronCanonicalizer()
        let poly = Polyhedron(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0], [0.0, 0.0, 0.0]],
            faces: [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]],
            name: "Test"
        )
        
        let canonical = await canonicalizer.canonicalize(poly, iterations: 1)
        
        XCTAssertGreaterThanOrEqual(canonical.vertices.count, 0)
        XCTAssertGreaterThanOrEqual(canonical.faces.count, 0)
    }
    
    func testAdjustXYZ() async {
        let canonicalizer = DefaultPolyhedronCanonicalizer()
        let poly = Polyhedron(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let adjusted = await canonicalizer.adjust(poly, iterations: 1)
        
        XCTAssertEqual(adjusted.vertices.count, poly.vertices.count)
        XCTAssertEqual(adjusted.faces.count, poly.faces.count)
    }
}

