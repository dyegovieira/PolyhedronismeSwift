import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronModelTests: XCTestCase {
    func testInitializerWithDefaults() {
        let model = PolyhedronModel()
        XCTAssertTrue(model.vertices.isEmpty)
        XCTAssertTrue(model.faces.isEmpty)
        XCTAssertEqual(model.name, "null polyhedron")
        XCTAssertTrue(model.faceClasses.isEmpty)
    }
    
    func testInitializerWithParameters() {
        let vertices: [Vec3] = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
        let faces: [Face] = [[0, 1, 2]]
        let name = "Test Polyhedron"
        let faceClasses = [1, 2, 3]
        
        let model = PolyhedronModel(
            vertices: vertices,
            faces: faces,
            name: name,
            faceClasses: faceClasses
        )
        
        XCTAssertEqual(model.vertices, vertices)
        XCTAssertEqual(model.faces, faces)
        XCTAssertEqual(model.name, name)
        XCTAssertEqual(model.faceClasses, faceClasses)
    }
    
    func testIsEmpty() {
        let emptyModel = PolyhedronModel()
        XCTAssertTrue(emptyModel.isEmpty)
        
        let modelWithVertices = PolyhedronModel(vertices: [[1.0, 2.0, 3.0]])
        XCTAssertTrue(modelWithVertices.isEmpty, "Should be empty if no faces")
        
        let modelWithFaces = PolyhedronModel(faces: [[0, 1, 2]])
        XCTAssertTrue(modelWithFaces.isEmpty, "Should be empty if no vertices")
        
        let fullModel = PolyhedronModel(
            vertices: [[1.0, 2.0, 3.0]],
            faces: [[0, 1, 2]]
        )
        XCTAssertFalse(fullModel.isEmpty)
    }
    
    func testVertexCount() {
        let model = PolyhedronModel(vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
        XCTAssertEqual(model.vertexCount, 2)
        
        let emptyModel = PolyhedronModel()
        XCTAssertEqual(emptyModel.vertexCount, 0)
    }
    
    func testFaceCount() {
        let model = PolyhedronModel(faces: [[0, 1, 2], [1, 2, 3]])
        XCTAssertEqual(model.faceCount, 2)
        
        let emptyModel = PolyhedronModel()
        XCTAssertEqual(emptyModel.faceCount, 0)
    }
    
    func testEdgesAreCachedUntilGeometryChanges() async throws {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyEdgeCalculator(edgesToReturn: [[0, 1], [1, 2], [2, 0]])
        
        _ = try await model.cachedEdges(using: calculator)
        _ = try await model.cachedEdges(using: calculator)
        let firstEdgeCallCount = await calculator.calculateEdgesCallCount
        XCTAssertEqual(firstEdgeCallCount, 1)
        
        model.vertices.append([0, 0, 1])
        _ = try await model.cachedEdges(using: calculator)
        let secondEdgeCallCount = await calculator.calculateEdgesCallCount
        XCTAssertEqual(secondEdgeCallCount, 2)
    }
    
    func testCentersCacheInvalidatesOnFaceMutation() async throws {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyFaceCalculator(
            centersToReturn: [[0.3, 0.3, 0.0]],
            normalsToReturn: [[0.0, 0.0, 1.0]]
        )
        
        _ = try await model.cachedCenters(using: calculator)
        _ = try await model.cachedCenters(using: calculator)
        let firstCenterCallCount = await calculator.calculateCentersCallCount
        XCTAssertEqual(firstCenterCallCount, 1)
        
        // Test didSet observer with direct assignment
        model.faces = [[0, 1, 2], [0, 2, 1]]
        _ = try await model.cachedCenters(using: calculator)
        let secondCenterCallCount = await calculator.calculateCentersCallCount
        XCTAssertEqual(secondCenterCallCount, 2)
    }
    
    func testCentersCacheInvalidatesOnFaceDirectAssignment() async throws {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyFaceCalculator(
            centersToReturn: [[0.3, 0.3, 0.0]],
            normalsToReturn: [[0.0, 0.0, 1.0]]
        )
        
        _ = try await model.cachedCenters(using: calculator)
        let initialCenterCallCount = await calculator.calculateCentersCallCount
        XCTAssertEqual(initialCenterCallCount, 1)
        
        // Direct assignment should trigger didSet
        model.faces = [[0, 1, 2], [1, 2, 0]]
        _ = try await model.cachedCenters(using: calculator)
        let invalidatedCenterCallCount = await calculator.calculateCentersCallCount
        XCTAssertEqual(invalidatedCenterCallCount, 2)
    }
    
    func testEdgesCacheInvalidatesOnVerticesDirectAssignment() async throws {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyEdgeCalculator(edgesToReturn: [[0, 1], [1, 2], [2, 0]])
        
        _ = try await model.cachedEdges(using: calculator)
        let initialEdgeCallCount = await calculator.calculateEdgesCallCount
        XCTAssertEqual(initialEdgeCallCount, 1)
        
        // Direct assignment should trigger didSet
        model.vertices = [[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1]]
        _ = try await model.cachedEdges(using: calculator)
        let invalidatedEdgeCallCount = await calculator.calculateEdgesCallCount
        XCTAssertEqual(invalidatedEdgeCallCount, 2)
    }
    
    func testNormalsCacheInvalidatesOnVertexMutation() async throws {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyFaceCalculator(
            centersToReturn: [[0.3, 0.3, 0.0]],
            normalsToReturn: [[0.0, 0.0, 1.0]]
        )
        
        _ = try await model.cachedNormals(using: calculator)
        _ = try await model.cachedNormals(using: calculator)
        let firstNormalCallCount = await calculator.calculateNormalsCallCount
        XCTAssertEqual(firstNormalCallCount, 1)
        
        model.vertices.append([0, 0, 1])
        _ = try await model.cachedNormals(using: calculator)
        let secondNormalCallCount = await calculator.calculateNormalsCallCount
        XCTAssertEqual(secondNormalCallCount, 2)
    }
    
    func testInitFromPolyhedron() {
        let polyhedron = Polyhedron(
            vertices: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
            faces: [[0, 1, 2]],
            name: "Test Polyhedron",
            faceClasses: [1, 2],
            recipe: "I"
        )
        
        let model = PolyhedronModel(polyhedron)
        
        XCTAssertEqual(model.vertices, polyhedron.vertices)
        XCTAssertEqual(model.faces, polyhedron.faces)
        XCTAssertEqual(model.name, polyhedron.name)
        XCTAssertEqual(model.faceClasses, polyhedron.faceClasses)
    }
    
    func testInitFromPolyhedronWithoutRecipe() {
        let polyhedron = Polyhedron(
            vertices: [[1.0, 2.0, 3.0]],
            faces: [[0]],
            name: "Test"
        )
        
        let model = PolyhedronModel(polyhedron)
        
        XCTAssertEqual(model.vertices, polyhedron.vertices)
        XCTAssertEqual(model.faces, polyhedron.faces)
        XCTAssertEqual(model.name, polyhedron.name)
    }
}

private actor SpyEdgeCalculator: EdgeCalculator {
    var calculateEdgesCallCount = 0
    var edgesToReturn: [[Int]]
    
    init(edgesToReturn: [[Int]]) {
        self.edgesToReturn = edgesToReturn
    }
    
    func calculateEdges(from polyhedron: PolyhedronModel) async throws -> [[Int]] {
        calculateEdgesCallCount += 1
        return edgesToReturn
    }
    
    nonisolated func faceToEdges(_ face: Face) -> [[Int]] {
        return []
    }
}

private actor SpyFaceCalculator: FaceCalculator {
    var calculateCentersCallCount = 0
    var calculateNormalsCallCount = 0
    var centersToReturn: [Vec3]
    var normalsToReturn: [Vec3]
    
    init(centersToReturn: [Vec3], normalsToReturn: [Vec3]) {
        self.centersToReturn = centersToReturn
        self.normalsToReturn = normalsToReturn
    }
    
    func calculateCenters(from polyhedron: PolyhedronModel) async throws -> [Vec3] {
        calculateCentersCallCount += 1
        return centersToReturn
    }
    
    func calculateNormals(from polyhedron: PolyhedronModel) async throws -> [Vec3] {
        calculateNormalsCallCount += 1
        return normalsToReturn
    }
}
