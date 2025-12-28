import XCTest
@testable import PolyhedronismeSwift

final class DefaultPolyhedronGeneratorTests: XCTestCase {
    private let generator: DefaultPolyhedronGenerator = {
        let baseRegistry = StandardBaseRegistry.makeDefault()
        let operatorRegistry = StandardOperatorRegistry.makeDefault()
        
        let metalConfig = MetalContext()
        let pipelineFactory = ComputePipelineFactory(metalConfig: metalConfig)
        let operatorFactory = DefaultOperatorFactory(
            operatorRegistry: operatorRegistry,
            metalConfig: metalConfig,
            pipelineFactory: pipelineFactory
        )
        
        return DefaultPolyhedronGenerator(
            baseRegistry: baseRegistry,
            operatorRegistry: operatorRegistry,
            operatorFactory: operatorFactory
        )
    }()
    
    func testGenerateSimpleBase() async throws {
        let result = try await generator.generate(notation: "I")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.name, "I")
    }
    
    func testGenerateWithOperator() async throws {
        let result = try await generator.generate(notation: "dI")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateUnknownBase() async {
        do {
            _ = try await generator.generate(notation: "X")
            XCTFail("Expected unknown base to throw")
        } catch {
            XCTAssertTrue(error is GenerationError)
        }
    }
    
    func testGenerateUnknownOperator() async {
        do {
            _ = try await generator.generate(notation: "xI")
            XCTFail("Expected unknown operator to throw")
        } catch {
            XCTAssertTrue(error is GenerationError)
        }
    }
    
    func testGenerateParameterizedBase() async throws {
        let result = try await generator.generate(notation: "P6")
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testGenerateErrorTypes() async {
        do {
            _ = try await generator.generate(notation: "X")
            XCTFail("Expected error")
        } catch let error as GenerationError {
            switch error {
            case .parsingFailed, .baseGenerationFailed, .operatorApplicationFailed, .canonicalizationFailed:
                break
            }
        } catch {
            XCTFail("Expected GenerationError, got \(type(of: error))")
        }
    }
    
    func testGenerateWithInvalidNotation() async {
        do {
            _ = try await generator.generate(notation: "")
            XCTFail("Expected error for empty notation")
        } catch {
            XCTAssertTrue(error is GenerationError || error is ParseError)
        }
    }
}

