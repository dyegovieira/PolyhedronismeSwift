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
    
    func testEdgesAreCachedUntilGeometryChanges() async {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyEdgeCalculator(edgesToReturn: [[0, 1], [1, 2], [2, 0]])
        
        _ = await model.cachedEdges(using: calculator)
        _ = await model.cachedEdges(using: calculator)
        XCTAssertEqual(calculator.calculateEdgesCallCount, 1)
        
        model.vertices.append([0, 0, 1])
        _ = await model.cachedEdges(using: calculator)
        XCTAssertEqual(calculator.calculateEdgesCallCount, 2)
    }
    
    func testCentersCacheInvalidatesOnFaceMutation() async {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyFaceCalculator(
            centersToReturn: [[0.3, 0.3, 0.0]],
            normalsToReturn: [[0.0, 0.0, 1.0]]
        )
        
        _ = await model.cachedCenters(using: calculator)
        _ = await model.cachedCenters(using: calculator)
        XCTAssertEqual(calculator.calculateCentersCallCount, 1)
        
        // Test didSet observer with direct assignment
        model.faces = [[0, 1, 2], [0, 2, 1]]
        _ = await model.cachedCenters(using: calculator)
        XCTAssertEqual(calculator.calculateCentersCallCount, 2)
    }
    
    func testCentersCacheInvalidatesOnFaceDirectAssignment() async {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyFaceCalculator(
            centersToReturn: [[0.3, 0.3, 0.0]],
            normalsToReturn: [[0.0, 0.0, 1.0]]
        )
        
        _ = await model.cachedCenters(using: calculator)
        XCTAssertEqual(calculator.calculateCentersCallCount, 1)
        
        // Direct assignment should trigger didSet
        model.faces = [[0, 1, 2], [1, 2, 0]]
        _ = await model.cachedCenters(using: calculator)
        XCTAssertEqual(calculator.calculateCentersCallCount, 2)
    }
    
    func testEdgesCacheInvalidatesOnVerticesDirectAssignment() async {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyEdgeCalculator(edgesToReturn: [[0, 1], [1, 2], [2, 0]])
        
        _ = await model.cachedEdges(using: calculator)
        XCTAssertEqual(calculator.calculateEdgesCallCount, 1)
        
        // Direct assignment should trigger didSet
        model.vertices = [[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1]]
        _ = await model.cachedEdges(using: calculator)
        XCTAssertEqual(calculator.calculateEdgesCallCount, 2)
    }
    
    func testNormalsCacheInvalidatesOnVertexMutation() async {
        var model = PolyhedronModel(
            vertices: [[0, 0, 0], [1, 0, 0], [0, 1, 0]],
            faces: [[0, 1, 2]]
        )
        let calculator = SpyFaceCalculator(
            centersToReturn: [[0.3, 0.3, 0.0]],
            normalsToReturn: [[0.0, 0.0, 1.0]]
        )
        
        _ = await model.cachedNormals(using: calculator)
        _ = await model.cachedNormals(using: calculator)
        XCTAssertEqual(calculator.calculateNormalsCallCount, 1)
        
        model.vertices.append([0, 0, 1])
        _ = await model.cachedNormals(using: calculator)
        XCTAssertEqual(calculator.calculateNormalsCallCount, 2)
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

private final class SpyEdgeCalculator: EdgeCalculator {
    var calculateEdgesCallCount = 0
    var edgesToReturn: [[Int]]
    
    init(edgesToReturn: [[Int]]) {
        self.edgesToReturn = edgesToReturn
    }
    
    func calculateEdges(from polyhedron: PolyhedronModel) async -> [[Int]] {
        calculateEdgesCallCount += 1
        return edgesToReturn
    }
    
    func faceToEdges(_ face: Face) -> [[Int]] {
        return []
    }
}

extension SpyEdgeCalculator: @unchecked Sendable {}

private final class SpyFaceCalculator: FaceCalculator {
    var calculateCentersCallCount = 0
    var calculateNormalsCallCount = 0
    var centersToReturn: [Vec3]
    var normalsToReturn: [Vec3]
    
    init(centersToReturn: [Vec3], normalsToReturn: [Vec3]) {
        self.centersToReturn = centersToReturn
        self.normalsToReturn = normalsToReturn
    }
    
    func calculateCenters(from polyhedron: PolyhedronModel) async -> [Vec3] {
        calculateCentersCallCount += 1
        return centersToReturn
    }
    
    func calculateNormals(from polyhedron: PolyhedronModel) async -> [Vec3] {
        calculateNormalsCallCount += 1
        return normalsToReturn
    }
}

extension SpyFaceCalculator: @unchecked Sendable {}

