//
// PolyhedronismeSwift
// PolyhedronismeSwiftGeneratorTests.swift
//
// Unit tests for PolyhedronismeSwiftGenerator - the main entry point
//
// Created by Dyego Vieira de Paula on 2025-12-10
// Built with AI-assisted development via Cursor IDE
//
import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronismeSwiftGeneratorTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitCreatesGenerator() {
        let generator = PolyhedronismeSwiftGenerator()
        XCTAssertNotNil(generator)
    }
    
    func testInitCanBeCalledMultipleTimes() {
        let generator1 = PolyhedronismeSwiftGenerator()
        let generator2 = PolyhedronismeSwiftGenerator()
        XCTAssertNotNil(generator1)
        XCTAssertNotNil(generator2)
    }
    
    // MARK: - Generate Tests - Basic Functionality
    
    func testGenerateSimpleBase() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "I")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.name, "I")
        XCTAssertEqual(result.recipe, "I")
    }
    
    func testGeneratePreservesRecipe() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let recipe = "dkI"
        let result = try await generator.generate(recipe: recipe)
        
        XCTAssertEqual(result.recipe, recipe)
    }
    
    func testGenerateWithOperator() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "dI")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "dI")
    }
    
    func testGenerateWithMultipleOperators() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "dkI")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "dkI")
    }
    
    func testGenerateParameterizedBase() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "P5")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "P5")
    }
    
    func testGenerateParameterizedOperator() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "k3I")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "k3I")
    }
    
    // MARK: - Generate Tests - Model Conversion
    
    func testGenerateConvertsModelToPolyhedron() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "T")
        
        // Verify all PolyhedronModel fields are correctly converted
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertNotEqual(result.name, "")
        // Face classes are preserved from the model (may be empty for base polyhedra)
        // Tetrahedron has 4 faces but base generators set faceClasses to empty array
        XCTAssertEqual(result.faces.count, 4)
        XCTAssertEqual(result.faceClasses.count, 0) // Base generators set faceClasses to []
    }
    
    func testGeneratePreservesFaceClasses() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "I")
        
        // Face classes are preserved from the model (base generators set them to empty array)
        // The important thing is that they're correctly passed through from model to Polyhedron
        // Icosahedron has 20 faces but base generators set faceClasses to empty array
        XCTAssertEqual(result.faces.count, 20)
        XCTAssertEqual(result.faceClasses.count, 0) // Base generators set faceClasses to []
    }
    
    func testGeneratePreservesVerticesAndFaces() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "C")
        
        // Verify vertices and faces are properly converted
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        
        // All vertices should have 3 coordinates
        for vertex in result.vertices {
            XCTAssertEqual(vertex.count, 3)
            XCTAssertTrue(vertex.allSatisfy { $0.isFinite })
        }
        
        // All faces should reference valid vertices
        for face in result.faces {
            XCTAssertFalse(face.isEmpty)
            XCTAssertGreaterThanOrEqual(face.count, 3)
            for vertexIndex in face {
                XCTAssertGreaterThanOrEqual(vertexIndex, 0)
                XCTAssertLessThan(vertexIndex, result.vertices.count)
            }
        }
    }
    
    // MARK: - Generate Tests - Error Handling
    
    func testGenerateThrowsOnInvalidBase() async {
        let generator = PolyhedronismeSwiftGenerator()
        
        do {
            _ = try await generator.generate(recipe: "X")
            XCTFail("Expected error for invalid base")
        } catch {
            XCTAssertTrue(error is GenerationError || error is ParseError)
        }
    }
    
    func testGenerateThrowsOnInvalidOperator() async {
        let generator = PolyhedronismeSwiftGenerator()
        
        do {
            _ = try await generator.generate(recipe: "xI")
            XCTFail("Expected error for invalid operator")
        } catch {
            XCTAssertTrue(error is GenerationError || error is ParseError)
        }
    }
    
    func testGenerateThrowsOnEmptyRecipe() async {
        let generator = PolyhedronismeSwiftGenerator()
        
        do {
            _ = try await generator.generate(recipe: "")
            XCTFail("Expected error for empty recipe")
        } catch {
            XCTAssertTrue(error is GenerationError || error is ParseError)
        }
    }
    
    func testGenerateThrowsOnMalformedRecipe() async {
        let generator = PolyhedronismeSwiftGenerator()
        
        do {
            _ = try await generator.generate(recipe: "123")
            XCTFail("Expected error for malformed recipe")
        } catch {
            XCTAssertTrue(error is GenerationError || error is ParseError)
        }
    }
    
    // MARK: - Generate Tests - Different Base Types
    
    func testGenerateTetrahedron() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "T")
        
        XCTAssertEqual(result.name, "T")
        XCTAssertEqual(result.recipe, "T")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateCube() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "C")
        
        XCTAssertEqual(result.name, "C")
        XCTAssertEqual(result.recipe, "C")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateOctahedron() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "O")
        
        XCTAssertEqual(result.name, "O")
        XCTAssertEqual(result.recipe, "O")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateDodecahedron() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "D")
        
        XCTAssertEqual(result.name, "D")
        XCTAssertEqual(result.recipe, "D")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateIcosahedron() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "I")
        
        XCTAssertEqual(result.name, "I")
        XCTAssertEqual(result.recipe, "I")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    // MARK: - Generate Tests - Complex Recipes
    
    func testGenerateComplexRecipe() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "gdkI")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "gdkI")
    }
    
    func testGenerateWithParameterizedOperator() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "tu3I")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "tu3I")
    }
    
    func testGenerateWithMultipleParameterizedOperators() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "k3u5I")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, "k3u5I")
    }
    
    // MARK: - Stream Tests
    
    func testStreamReturnsAsyncThrowingStream() {
        let generator = PolyhedronismeSwiftGenerator()
        let stream = generator.stream(recipe: "I")
        
        // Verify it returns the correct type
        XCTAssertNotNil(stream)
    }
    
    func testStreamCanBeCalledMultipleTimes() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        
        // First stream
        var count1 = 0
        for try await _ in generator.stream(recipe: "I") {
            count1 += 1
        }
        
        // Second stream
        var count2 = 0
        for try await _ in generator.stream(recipe: "C") {
            count2 += 1
        }
        
        // Both should complete
        XCTAssertGreaterThan(count1, 0)
        XCTAssertGreaterThan(count2, 0)
    }
    
    // MARK: - Concurrency Tests
    
    func testGenerateIsThreadSafe() async throws {
        try await withThrowingTaskGroup(of: Polyhedron.self) { group in
            for recipe in ["I", "C", "O", "T", "D"] {
                group.addTask {
                    let generator = PolyhedronismeSwiftGenerator()
                    return try await generator.generate(recipe: recipe)
                }
            }
            
            var results: [Polyhedron] = []
            for try await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, 5)
            for result in results {
                XCTAssertFalse(result.vertices.isEmpty)
                XCTAssertFalse(result.faces.isEmpty)
                XCTAssertNotNil(result.recipe)
            }
        }
    }
    
    func testMultipleGeneratorsCanRunConcurrently() async throws {
        let generator1 = PolyhedronismeSwiftGenerator()
        let generator2 = PolyhedronismeSwiftGenerator()
        
        async let result1 = generator1.generate(recipe: "I")
        async let result2 = generator2.generate(recipe: "C")
        
        let poly1 = try await result1
        let poly2 = try await result2
        
        XCTAssertEqual(poly1.recipe, "I")
        XCTAssertEqual(poly2.recipe, "C")
        XCTAssertFalse(poly1.vertices.isEmpty)
        XCTAssertFalse(poly2.vertices.isEmpty)
    }
    
    // MARK: - Recipe Edge Cases
    
    func testGenerateWithVeryLongRecipe() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        // Create a recipe with many operators
        let longRecipe = String(repeating: "d", count: 10) + "I"
        let result = try await generator.generate(recipe: longRecipe)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, longRecipe)
    }
    
    func testGenerateWithAllOperators() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        // Test with all available operators
        let complexRecipe = "adgkrpI"
        let result = try await generator.generate(recipe: complexRecipe)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.recipe, complexRecipe)
    }
    
    // MARK: - Recipe Validation Tests
    
    func testGenerateWithPrism() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "P6")
        
        XCTAssertEqual(result.recipe, "P6")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateWithAntiprism() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "A6")
        
        XCTAssertEqual(result.recipe, "A6")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateWithPyramid() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "Y5")
        
        XCTAssertEqual(result.recipe, "Y5")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateWithCupola() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "U5")
        
        XCTAssertEqual(result.recipe, "U5")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateWithAnticupola() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let result = try await generator.generate(recipe: "V5")
        
        XCTAssertEqual(result.recipe, "V5")
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    func testGenerateAndStreamProduceSameResult() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let recipe = "I"
        
        // Generate directly
        let directResult = try await generator.generate(recipe: recipe)
        
        // Generate via stream
        var streamResult: Polyhedron?
        for try await event in generator.stream(recipe: recipe) {
            if case .completed(let polyhedron) = event {
                streamResult = polyhedron
            }
        }
        
        XCTAssertNotNil(streamResult)
        XCTAssertEqual(directResult.recipe, streamResult?.recipe)
        XCTAssertEqual(directResult.vertices.count, streamResult?.vertices.count)
        XCTAssertEqual(directResult.faces.count, streamResult?.faces.count)
    }
    
    // MARK: - Error Message Tests
    
    func testGenerateErrorMessagesAreDescriptive() async {
        let generator = PolyhedronismeSwiftGenerator()
        
        do {
            _ = try await generator.generate(recipe: "InvalidRecipe123")
            XCTFail("Expected error")
        } catch {
            let errorMessage = error.localizedDescription
            XCTAssertFalse(errorMessage.isEmpty)
            // Error should mention something about the failure
            XCTAssertTrue(
                errorMessage.contains("Invalid") ||
                errorMessage.contains("Unknown") ||
                errorMessage.contains("Parsing") ||
                errorMessage.contains("notation")
            )
        }
    }
}

