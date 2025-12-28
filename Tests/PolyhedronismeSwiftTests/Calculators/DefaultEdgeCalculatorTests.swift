import XCTest
@testable import PolyhedronismeSwift

final class DefaultEdgeCalculatorTests: XCTestCase {
    private let calculator = DefaultEdgeCalculator()
    
    func testFaceToEdges() {
        let face: Face = [0, 1, 2]
        let edges = calculator.faceToEdges(face)
        
        XCTAssertEqual(edges.count, 3)
        XCTAssertTrue(edges.contains([2, 0]))
        XCTAssertTrue(edges.contains([0, 1]))
        XCTAssertTrue(edges.contains([1, 2]))
    }
    
    func testFaceToEdgesWithTwoVertices() {
        let face: Face = [0, 1]
        let edges = calculator.faceToEdges(face)
        XCTAssertEqual(edges.count, 2)
    }
    
    func testFaceToEdgesWithOneVertex() {
        let face: Face = [0]
        let edges = calculator.faceToEdges(face)
        XCTAssertTrue(edges.isEmpty)
    }
    
    func testCalculateEdges() async {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let edges = await calculator.calculateEdges(from: model)
        
        XCTAssertFalse(edges.isEmpty)
        for edge in edges {
            XCTAssertEqual(edge.count, 2)
        }
    }
    
    func testCalculateEdgesWithDuplicateEdges() async {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2], [0, 2, 1]],
            name: "Test"
        )
        
        let edges = await calculator.calculateEdges(from: model)
        
        let uniqueEdgeCount = Set(edges.map { "\($0[0])-\($0[1])" }).count
        XCTAssertEqual(uniqueEdgeCount, edges.count)
    }
    
    func testEdgeKeyIgnoresVertexOrder() {
        let keyA = EdgeKey(2, 5)
        let keyB = EdgeKey(5, 2)
        XCTAssertEqual(keyA, keyB)
        XCTAssertEqual(keyA.lower, 2)
        XCTAssertEqual(keyA.upper, 5)
    }
}

