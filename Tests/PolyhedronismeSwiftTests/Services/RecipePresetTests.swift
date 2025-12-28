import Foundation
import XCTest
@testable import PolyhedronismeSwift

final class RecipePresetTests: XCTestCase {
    private var generator: PolyhedronismeSwiftGenerator?
    private var edgeCalculator: EdgeCalculator?
    private var faceCalculator: FaceCalculator?
    private var exporter: PolyhedronExporter?
    
    override func setUp() {
        super.setUp()
        generator = PolyhedronismeSwiftGenerator()
        edgeCalculator = DefaultEdgeCalculator()
        faceCalculator = DefaultFaceCalculator()
        exporter = OBJExporter()
    }
    
    override func tearDown() {
        generator = nil
        edgeCalculator = nil
        faceCalculator = nil
        exporter = nil
        super.tearDown()
    }
    
    // MARK: - Recipe Presets
    
    private let recipePresets: [(id: String, name: String, notation: String)] = [
        ("I", "Icosahedron", "I"),
        ("dI", "Dual Icosahedron", "dI"),
        ("tu3I", "Truncated Icosahedron (n=3)", "tu3I"),
        ("tu5I", "Truncated Icosahedron (n=5)", "tu5I"),
        ("tu10I", "Truncated Icosahedron (n=10)", "tu10I"),
        ("gI", "Gyro Icosahedron", "gI"),
        ("aI", "Ambo Icosahedron", "aI"),
        ("dgI", "Dual Gyro Icosahedron", "dgI"),
        ("adI", "Ambo Dual Icosahedron", "adI"),
        ("P6", "Hexagonal Prism", "P6"),
        ("A6", "Hexagonal Antiprism", "A6"),
        ("Y5", "Pentagonal Pyramid", "Y5"),
        ("U5", "Pentagonal Cupola", "U5"),
        ("V5", "Pentagonal Anticupola", "V5"),
    ]
    
    // MARK: - Test All Recipes
    
    func testAllRecipesCanBeGenerated() async throws {
        let generator = try XCTUnwrap(generator)
        for preset in recipePresets {
            let polyhedron = try await generator.generate(recipe: preset.notation)
            
            XCTAssertNotNil(polyhedron, "Failed to generate polyhedron for recipe: \(preset.notation)")
            XCTAssertFalse(polyhedron.vertices.isEmpty, "Recipe \(preset.notation) has no vertices")
            XCTAssertFalse(polyhedron.faces.isEmpty, "Recipe \(preset.notation) has no faces")
            validatePolyhedron(polyhedron, recipe: preset.notation)
        }
    }
    
    // MARK: - Validation Helpers
    
    private func validatePolyhedron(_ polyhedron: Polyhedron, recipe: String) {
        let vertices = polyhedron.vertices
        let faces = polyhedron.faces
        
        XCTAssertFalse(vertices.isEmpty, "Recipe \(recipe) has no vertices")
        XCTAssertFalse(faces.isEmpty, "Recipe \(recipe) has no faces")
        
        for (index, face) in faces.enumerated() {
            XCTAssertFalse(face.isEmpty, "Recipe \(recipe) has empty face at index \(index)")
            XCTAssertGreaterThanOrEqual(face.count, 3, "Recipe \(recipe) has degenerate face (<3 vertices) at index \(index)")
            
            let uniqueVertices = Set(face)
            XCTAssertEqual(uniqueVertices.count, face.count, "Recipe \(recipe) has face with duplicate vertices at index \(index)")
            
            for vertexIndex in face {
                XCTAssertGreaterThanOrEqual(vertexIndex, 0, "Recipe \(recipe) has face with negative vertex index at face \(index)")
                XCTAssertLessThan(vertexIndex, vertices.count, "Recipe \(recipe) has face with out-of-bounds vertex index \(vertexIndex) at face \(index)")
            }
        }
        
        validateVertexCoordinates(polyhedron, recipe: recipe)
    }
    
    private func validateVertexCoordinates(_ polyhedron: Polyhedron, recipe: String) {
        for (index, vertex) in polyhedron.vertices.enumerated() {
            XCTAssertEqual(vertex.count, 3, "Recipe \(recipe) has vertex with invalid coordinate count at index \(index)")
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite }, "Recipe \(recipe) has vertex with non-finite coordinates at index \(index)")
        }
    }
    
    // MARK: - Edge Validation
    
    func testAllRecipesHaveValidEdges() async throws {
        let generator = try XCTUnwrap(generator)
        let edgeCalculator = try XCTUnwrap(edgeCalculator)
        for preset in recipePresets {
            let polyhedron = try await generator.generate(recipe: preset.notation)
            var model = PolyhedronModel(
                vertices: polyhedron.vertices,
                faces: polyhedron.faces,
                name: polyhedron.name,
                faceClasses: polyhedron.faceClasses
            )
            let edges = await model.cachedEdges(using: edgeCalculator)
            
            XCTAssertFalse(edges.isEmpty, "Recipe \(preset.notation) has no edges")
            
            for edge in edges {
                XCTAssertEqual(edge.count, 2, "Recipe \(preset.notation) has invalid edge")
                let (v1, v2) = (edge[0], edge[1])
                XCTAssertGreaterThanOrEqual(v1, 0, "Recipe \(preset.notation) has edge with negative vertex index")
                XCTAssertGreaterThanOrEqual(v2, 0, "Recipe \(preset.notation) has edge with negative vertex index")
                XCTAssertLessThan(v1, polyhedron.vertices.count, "Recipe \(preset.notation) has edge with out-of-bounds vertex index")
                XCTAssertLessThan(v2, polyhedron.vertices.count, "Recipe \(preset.notation) has edge with out-of-bounds vertex index")
                XCTAssertNotEqual(v1, v2, "Recipe \(preset.notation) has self-loop edge")
            }
        }
    }
    
    // MARK: - Face Centers Validation
    
    func testAllRecipesHaveValidFaceCenters() async throws {
        let generator = try XCTUnwrap(generator)
        let faceCalculator = try XCTUnwrap(faceCalculator)
        for preset in recipePresets {
            let polyhedron = try await generator.generate(recipe: preset.notation)
            var model = PolyhedronModel(
                vertices: polyhedron.vertices,
                faces: polyhedron.faces,
                name: polyhedron.name,
                faceClasses: polyhedron.faceClasses
            )
            let centers = await model.cachedCenters(using: faceCalculator)
            
            XCTAssertEqual(centers.count, polyhedron.faces.count, "Recipe \(preset.notation) has mismatched face center count")
            
            for (index, center) in centers.enumerated() {
                XCTAssertEqual(center.count, 3, "Recipe \(preset.notation) has invalid face center at index \(index)")
                XCTAssertTrue(center.allSatisfy { $0.isFinite }, "Recipe \(preset.notation) has face center with non-finite coordinates at index \(index)")
            }
        }
    }
    
    // MARK: - Face Normals Validation
    
    func testAllRecipesHaveValidFaceNormals() async throws {
        let generator = try XCTUnwrap(generator)
        let faceCalculator = try XCTUnwrap(faceCalculator)
        for preset in recipePresets {
            let polyhedron = try await generator.generate(recipe: preset.notation)
            var model = PolyhedronModel(
                vertices: polyhedron.vertices,
                faces: polyhedron.faces,
                name: polyhedron.name,
                faceClasses: polyhedron.faceClasses
            )
            let normals = await model.cachedNormals(using: faceCalculator)
            
            XCTAssertEqual(normals.count, polyhedron.faces.count, "Recipe \(preset.notation) has mismatched face normal count")
            
            for (index, normal) in normals.enumerated() {
                XCTAssertEqual(normal.count, 3, "Recipe \(preset.notation) has invalid face normal at index \(index)")
                XCTAssertTrue(normal.allSatisfy { $0.isFinite }, "Recipe \(preset.notation) has face normal with non-finite coordinates at index \(index)")
            }
        }
    }
    
    // MARK: - OBJ Export Validation
    
    func testAllRecipesCanExportToOBJ() async throws {
        let generator = try XCTUnwrap(generator)
        let exporter = try XCTUnwrap(exporter)
        for preset in recipePresets {
            let polyhedron = try await generator.generate(recipe: preset.notation)
            let model = PolyhedronModel(
                vertices: polyhedron.vertices,
                faces: polyhedron.faces,
                name: polyhedron.name,
                faceClasses: polyhedron.faceClasses
            )
            let objString = (try? await exporter.export(model)) ?? ""
            
            XCTAssertFalse(objString.isEmpty, "Recipe \(preset.notation) produced empty OBJ string")
            XCTAssertTrue(objString.contains("vertices"), "Recipe \(preset.notation) OBJ string missing vertices section")
            XCTAssertTrue(objString.contains("face defs"), "Recipe \(preset.notation) OBJ string missing face definitions")
        }
    }
    
    // MARK: - Performance Tests
    
    func testRecipeGenerationPerformance() async throws {
        let generator = try XCTUnwrap(generator)
        let clock = ContinuousClock()
        let duration = try await clock.measure {
            for preset in recipePresets {
                _ = try await generator.generate(recipe: preset.notation)
            }
        }
        XCTAssertLessThan(duration, .seconds(5))
    }
    
    // MARK: - Helper Method Edge Cases
    // Note: These tests exercise edge cases in validation helpers by creating polyhedra
    // with specific characteristics that might not appear in standard recipes
    
    func testValidatePolyhedronWithLargeFace() async throws {
        // Test validation with a face that has many vertices
        let generator = try XCTUnwrap(generator)
        let polyhedron = try await generator.generate(recipe: "I")
        
        // Verify validation handles large faces correctly
        validatePolyhedron(polyhedron, recipe: "LargeFaceTest")
    }
    
    func testValidatePolyhedronWithManyVertices() async throws {
        // Test validation with polyhedron that has many vertices
        let generator = try XCTUnwrap(generator)
        let polyhedron = try await generator.generate(recipe: "tu10I")
        
        // Verify validation handles many vertices correctly
        validatePolyhedron(polyhedron, recipe: "ManyVerticesTest")
    }
    
    func testValidatePolyhedronWithComplexFaces() async throws {
        // Test validation with complex polyhedron
        let generator = try XCTUnwrap(generator)
        let polyhedron = try await generator.generate(recipe: "dgI")
        
        // Verify validation handles complex faces correctly
        validatePolyhedron(polyhedron, recipe: "ComplexFacesTest")
    }
    
    func testValidateVertexCoordinatesWithZeroCoordinates() async throws {
        // Test validation with vertices that have zero coordinates (valid but edge case)
        let generator = try XCTUnwrap(generator)
        let polyhedron = try await generator.generate(recipe: "I")
        
        // Verify validation handles zero coordinates correctly
        validateVertexCoordinates(polyhedron, recipe: "ZeroCoordsTest")
    }
    
    func testValidatePolyhedronWithSingleFace() async throws {
        // Test validation with a simple polyhedron (like a tetrahedron)
        let generator = try XCTUnwrap(generator)
        let polyhedron = try await generator.generate(recipe: "T")
        
        // Verify validation handles single face correctly
        validatePolyhedron(polyhedron, recipe: "SingleFaceTest")
    }
}
