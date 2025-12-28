import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronMetricsTests: XCTestCase {
    private let metrics = DefaultPolyhedronMetrics()
    private let edgeCalculator = DefaultEdgeCalculator()
    private let faceCalculator = DefaultFaceCalculator()
    
    // MARK: - calculateDataDescription Tests
    
    func testCalculateDataDescription() {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let description = metrics.calculateDataDescription(from: model)
        
        XCTAssertTrue(description.contains("1 faces"), "Should contain face count")
        XCTAssertTrue(description.contains("2 edges"), "Should contain edge count (1+3-2=2)")
        XCTAssertTrue(description.contains("3 vertices"), "Should contain vertex count")
    }
    
    func testCalculateDataDescriptionWithEmptyModel() {
        let model = PolyhedronModel(vertices: [], faces: [], name: "Empty")
        let description = metrics.calculateDataDescription(from: model)
        
        XCTAssertTrue(description.contains("0 faces"), "Should contain 0 faces")
        XCTAssertTrue(description.contains("-2 edges"), "Should contain -2 edges (0+0-2)")
        XCTAssertTrue(description.contains("0 vertices"), "Should contain 0 vertices")
    }
    
    func testCalculateDataDescriptionWithMultipleFaces() {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0]
            ],
            faces: [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]],
            name: "Tetrahedron"
        )
        
        let description = metrics.calculateDataDescription(from: model)
        
        XCTAssertTrue(description.contains("4 faces"), "Should contain face count")
        XCTAssertTrue(description.contains("6 edges"), "Should contain edge count (4+4-2=6)")
        XCTAssertTrue(description.contains("4 vertices"), "Should contain vertex count")
    }
    
    // MARK: - calculateDetailedDescription Tests
    
    func testCalculateDetailedDescription() async {
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let description = await metrics.calculateDetailedDescription(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        XCTAssertTrue(description.contains("min edge length"), "Should contain min edge length")
        XCTAssertTrue(description.contains("min face radius"), "Should contain min face radius")
        XCTAssertTrue(description.contains("\n"), "Should contain newline separator")
    }
    
    func testCalculateDetailedDescriptionWithEmptyModel() async {
        let model = PolyhedronModel(vertices: [], faces: [], name: "Empty")
        
        let description = await metrics.calculateDetailedDescription(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        XCTAssertTrue(description.contains("min edge length"), "Should contain min edge length")
        XCTAssertTrue(description.contains("min face radius"), "Should contain min face radius")
    }
    
    // MARK: - calculateMinEdgeLength Tests
    
    func testCalculateMinEdgeLength() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0]
            ],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let minEdge = await metrics.calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        
        XCTAssertGreaterThan(minEdge, 0, "Min edge should be positive")
        XCTAssertTrue(minEdge.isFinite, "Min edge should be finite")
        XCTAssertLessThanOrEqual(minEdge, sqrt(2.0), "Min edge should be <= diagonal length")
    }
    
    func testCalculateMinEdgeLengthWithUnitCube() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0],
                [1.0, 1.0, 0.0],
                [1.0, 0.0, 1.0],
                [0.0, 1.0, 1.0],
                [1.0, 1.0, 1.0]
            ],
            faces: [
                [0, 1, 2, 4],
                [0, 1, 5, 3],
                [0, 2, 6, 3],
                [1, 4, 7, 5],
                [2, 4, 7, 6],
                [3, 5, 7, 6]
            ],
            name: "Cube"
        )
        
        let minEdge = await metrics.calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        
        // Unit cube should have min edge length of 1.0
        XCTAssertEqual(minEdge, 1.0, accuracy: 1e-5, "Unit cube min edge should be 1.0")
    }
    
    func testCalculateMinEdgeLengthWithEmptyEdges() async {
        let model = PolyhedronModel(vertices: [], faces: [], name: "Empty")
        let minEdge = await metrics.calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        
        // When no edges, should return sqrt of greatestFiniteMagnitude
        let expected = sqrt(Double.greatestFiniteMagnitude)
        XCTAssertEqual(minEdge, expected, accuracy: 1e-10, "Empty model should return sqrt of greatestFiniteMagnitude")
    }
    
    func testCalculateMinEdgeLengthWithInvalidIndices() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0]],
            faces: [[0, 1, 2]], // Invalid indices (1 and 2 don't exist)
            name: "Test"
        )
        
        let minEdge = await metrics.calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        
        // Should handle invalid indices gracefully
        XCTAssertTrue(minEdge.isFinite || minEdge == sqrt(Double.greatestFiniteMagnitude), "Should handle invalid indices")
    }
    
    func testCalculateMinEdgeLengthWithSingleEdge() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0]
            ],
            faces: [[0, 1]],
            name: "SingleEdge"
        )
        
        let minEdge = await metrics.calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        
        XCTAssertEqual(minEdge, 1.0, accuracy: 1e-10, "Single edge of length 1 should return 1.0")
    }
    
    func testCalculateMinEdgeLengthWithDifferentLengths() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0], // Length 1
                [0.0, 2.0, 0.0], // Length 2
                [0.0, 0.0, 0.5]  // Length 0.5
            ],
            faces: [[0, 1], [0, 2], [0, 3]],
            name: "Test"
        )
        
        let minEdge = await metrics.calculateMinEdgeLength(from: model, edgeCalculator: edgeCalculator)
        
        // Should return the minimum edge length (0.5)
        XCTAssertEqual(minEdge, 0.5, accuracy: 1e-10, "Should return minimum edge length")
    }
    
    // MARK: - calculateMinFaceRadius Tests
    
    func testCalculateMinFaceRadius() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0]
            ],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        XCTAssertGreaterThan(minRadius, 0, "Min radius should be positive")
        XCTAssertTrue(minRadius.isFinite, "Min radius should be finite")
    }
    
    func testCalculateMinFaceRadiusWithEmptyFaces() async {
        let model = PolyhedronModel(vertices: [[0.0, 0.0, 0.0]], faces: [], name: "Empty")
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        // When no faces, should return sqrt of greatestFiniteMagnitude
        let expected = sqrt(Double.greatestFiniteMagnitude)
        XCTAssertEqual(minRadius, expected, accuracy: 1e-10, "Empty faces should return sqrt of greatestFiniteMagnitude")
    }
    
    func testCalculateMinFaceRadiusWithOutOfBoundsIndices() async {
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0]],
            faces: [[0, 1, 2]], // Invalid indices
            name: "Test"
        )
        
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        // Should handle invalid indices gracefully
        XCTAssertTrue(minRadius.isFinite || minRadius == sqrt(Double.greatestFiniteMagnitude), "Should handle invalid indices")
    }
    
    func testCalculateMinFaceRadiusWithMultipleFaces() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0]
            ],
            faces: [[0, 1, 2], [0, 1, 3]],
            name: "Test"
        )
        
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        XCTAssertGreaterThan(minRadius, 0, "Min radius should be positive")
        XCTAssertTrue(minRadius.isFinite, "Min radius should be finite")
    }
    
    func testCalculateMinFaceRadiusWithEquilateralTriangle() async {
        // Equilateral triangle with side length 1
        let side = 1.0
        let height = sqrt(3.0) / 2.0
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [side, 0.0, 0.0],
                [side / 2.0, height, 0.0]
            ],
            faces: [[0, 1, 2]],
            name: "EquilateralTriangle"
        )
        
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        // For equilateral triangle, the inradius is height/3
        let expectedInradius = height / 3.0
        XCTAssertGreaterThan(minRadius, 0, "Min radius should be positive")
        XCTAssertLessThanOrEqual(minRadius, expectedInradius * 2.0, "Min radius should be reasonable")
    }
    
    func testCalculateMinFaceRadiusWithSquare() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [1.0, 1.0, 0.0],
                [0.0, 1.0, 0.0]
            ],
            faces: [[0, 1, 2, 3]],
            name: "Square"
        )
        
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        // For a unit square, the distance from center to edge is 0.5
        XCTAssertGreaterThan(minRadius, 0, "Min radius should be positive")
        XCTAssertLessThanOrEqual(minRadius, 0.5, "Min radius for unit square should be <= 0.5")
    }
    
    func testCalculateMinFaceRadiusWithFaceIndexOutOfBounds() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0]
            ],
            faces: [[0, 1, 2], [0, 1, 2]], // Two faces
            name: "Test"
        )
        
        // This tests the guard faceIndex < centers.count
        // If centers array is smaller than faces, it should skip
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        XCTAssertTrue(minRadius.isFinite || minRadius == sqrt(Double.greatestFiniteMagnitude), "Should handle index out of bounds")
    }
    
    func testCalculateMinFaceRadiusWithSmallFaces() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0]
            ],
            faces: [[0, 1]], // Face with only 2 vertices (degenerate)
            name: "Test"
        )
        
        let minRadius = await metrics.calculateMinFaceRadius(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        // Should handle small faces gracefully
        XCTAssertTrue(minRadius.isFinite || minRadius == sqrt(Double.greatestFiniteMagnitude), "Should handle small faces")
    }
    
    // MARK: - Integration Tests
    
    func testFullMetricsCalculation() async {
        let model = PolyhedronModel(
            vertices: [
                [0.0, 0.0, 0.0],
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0]
            ],
            faces: [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]],
            name: "Tetrahedron"
        )
        
        let dataDescription = metrics.calculateDataDescription(from: model)
        let detailedDescription = await metrics.calculateDetailedDescription(
            from: model,
            edgeCalculator: edgeCalculator,
            faceCalculator: faceCalculator
        )
        
        XCTAssertFalse(dataDescription.isEmpty, "Data description should not be empty")
        XCTAssertFalse(detailedDescription.isEmpty, "Detailed description should not be empty")
        XCTAssertTrue(dataDescription.contains("4 faces"), "Should contain correct face count")
        XCTAssertTrue(detailedDescription.contains("min edge length"), "Should contain min edge length")
        XCTAssertTrue(detailedDescription.contains("min face radius"), "Should contain min face radius")
    }
}

