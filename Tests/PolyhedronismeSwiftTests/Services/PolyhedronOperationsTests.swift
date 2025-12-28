import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronOperationsTests: XCTestCase {
    private var operations: DefaultPolyhedronOperations?
    private var edgeCalculator: EdgeCalculator?
    
    override func setUp() {
        super.setUp()
        operations = DefaultPolyhedronOperations()
        edgeCalculator = DefaultEdgeCalculator()
    }
    
    override func tearDown() {
        operations = nil
        edgeCalculator = nil
        super.tearDown()
    }
    
    func testRecenter() async throws {
        let operations = try XCTUnwrap(operations)
        let edgeCalculator = try XCTUnwrap(edgeCalculator)
        
        let model = PolyhedronModel(
            vertices: [[10.0, 10.0, 10.0], [12.0, 12.0, 12.0], [14.0, 14.0, 14.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let result = await operations.recenter(model, edgeCalculator: edgeCalculator)
        
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        XCTAssertEqual(result.faces, model.faces)
        XCTAssertEqual(result.name, model.name)
    }
    
    func testRecenterWithEmptyEdges() async throws {
        let operations = try XCTUnwrap(operations)
        let edgeCalculator = try XCTUnwrap(edgeCalculator)
        
        let model = PolyhedronModel(
            vertices: [],
            faces: [],
            name: "Empty"
        )
        
        let result = await operations.recenter(model, edgeCalculator: edgeCalculator)
        XCTAssertEqual(result.vertices, model.vertices)
    }
    
    func testRescale() throws {
        let operations = try XCTUnwrap(operations)
        
        let model = PolyhedronModel(
            vertices: [[10.0, 0.0, 0.0], [0.0, 10.0, 0.0], [0.0, 0.0, 10.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let result = operations.rescale(model)
        
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        let maxMagnitude = result.vertices.map { Vector3.magnitude($0) }.max() ?? 0.0
        XCTAssertEqual(maxMagnitude, 1.0, accuracy: 1e-10)
    }
    
    func testRescaleWithZeroExtent() throws {
        let operations = try XCTUnwrap(operations)
        
        let model = PolyhedronModel(
            vertices: [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]],
            faces: [[0, 1]],
            name: "Test"
        )
        
        let result = operations.rescale(model)
        XCTAssertEqual(result.vertices, model.vertices)
    }
    
    func testRecenterWithInvalidEdges() async throws {
        let operations = try XCTUnwrap(operations)
        
        struct InvalidEdgeCalculator: EdgeCalculator {
            func faceToEdges(_ face: Face) -> [[Int]] {
                []
            }
            
            func calculateEdges(from polyhedron: PolyhedronModel) async -> [[Int]] {
                return [[0, 1], [1], [2, 3, 4], [5, 10]]
            }
        }
        
        let edgeCalculator = InvalidEdgeCalculator()
        let model = PolyhedronModel(
            vertices: [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
            faces: [[0, 1, 2]],
            name: "Test"
        )
        
        let result = await operations.recenter(model, edgeCalculator: edgeCalculator)
        
        XCTAssertEqual(result.vertices.count, model.vertices.count)
        XCTAssertEqual(result.faces, model.faces)
    }
}
