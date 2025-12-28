import XCTest
@testable import PolyhedronismeSwift

final class DefaultPolyhedronCanonicalizerTests: XCTestCase {
    private var canonicalizer: DefaultPolyhedronCanonicalizer?
    
    override func setUp() {
        super.setUp()
        canonicalizer = DefaultPolyhedronCanonicalizer()
    }
    
    override func tearDown() {
        canonicalizer = nil
        super.tearDown()
    }
    
    func testAdjust() async throws {
        let canonicalizer = try XCTUnwrap(canonicalizer)
        let tetrahedron = try await TetrahedronGenerator().generate()
        let polyhedron = Polyhedron(tetrahedron)
        
        let result = await canonicalizer.adjust(polyhedron, iterations: 1)
        
        XCTAssertEqual(result.vertices.count, polyhedron.vertices.count)
        XCTAssertEqual(result.faces.count, polyhedron.faces.count)
        XCTAssertEqual(result.name, polyhedron.name)
    }
    
    func testCanonicalize() async throws {
        let canonicalizer = try XCTUnwrap(canonicalizer)
        let tetrahedron = try await TetrahedronGenerator().generate()
        let polyhedron = Polyhedron(tetrahedron)
        
        let result = await canonicalizer.canonicalize(polyhedron, iterations: 1)
        
        XCTAssertEqual(result.vertices.count, polyhedron.vertices.count)
        XCTAssertEqual(result.faces.count, polyhedron.faces.count)
        XCTAssertEqual(result.name, polyhedron.name)
    }
    
    func testAdjustPreservesRecipe() async throws {
        let canonicalizer = try XCTUnwrap(canonicalizer)
        let tetrahedron = try await TetrahedronGenerator().generate()
        let polyhedron = Polyhedron(tetrahedron, recipe: "T")
        
        let result = await canonicalizer.adjust(polyhedron, iterations: 1)
        XCTAssertEqual(result.recipe, "T")
    }
    
    func testCanonicalizePreservesRecipe() async throws {
        let canonicalizer = try XCTUnwrap(canonicalizer)
        let tetrahedron = try await TetrahedronGenerator().generate()
        let polyhedron = Polyhedron(tetrahedron, recipe: "T")
        
        let result = await canonicalizer.canonicalize(polyhedron, iterations: 1)
        XCTAssertEqual(result.recipe, "T")
    }
    
    func testCanonicalizerWithZeroIterations() async throws {
        let canonicalizer = try XCTUnwrap(canonicalizer)
        let tetrahedron = try await TetrahedronGenerator().generate()
        let polyhedron = Polyhedron(tetrahedron)
        
        let result = await canonicalizer.canonicalize(polyhedron, iterations: 0)
        
        XCTAssertEqual(result.vertices.count, polyhedron.vertices.count)
        XCTAssertEqual(result.faces.count, polyhedron.faces.count)
    }
}
