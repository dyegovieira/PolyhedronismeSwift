import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronErrorTests: XCTestCase {
    func testPolyhedronErrorInvalidPolyhedron() {
        let error = PolyhedronError.invalidPolyhedron("test reason")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("test reason") ?? false)
    }
    
    func testPolyhedronErrorInvalidVertex() {
        let error = PolyhedronError.invalidVertex(5)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("5") ?? false)
    }
    
    func testPolyhedronErrorInvalidFace() {
        let error = PolyhedronError.invalidFace(3)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("3") ?? false)
    }
    
    func testPolyhedronErrorEmptyPolyhedron() {
        let error = PolyhedronError.emptyPolyhedron
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testPolyhedronErrorInvalidOperation() {
        let error = PolyhedronError.invalidOperation("test operation")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("test operation") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Invalid operation") ?? false)
    }
    
    func testPolyhedronErrorInternalError() {
        let error = PolyhedronError.internalError("test message")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("test message") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Internal error") ?? false)
    }
    
    func testOperatorErrorUnknownOperator() {
        let error = OperatorError.unknownOperator("x")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("x") ?? false)
    }
    
    func testOperatorErrorInvalidParameters() {
        let error = OperatorError.invalidParameters("test details", operator: "op")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("op") ?? false)
    }
    
    func testOperatorErrorOperationFailed() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "test error"])
        let error = OperatorError.operationFailed("testOp", underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("testOp") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("failed") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("test error") ?? false)
    }
    
    func testGenerationErrorParsingFailed() {
        let parseError = ParseError.emptyNotation
        let error = GenerationError.parsingFailed(parseError)
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testGenerationErrorBaseGenerationFailed() {
        let underlying = NSError(domain: "test", code: 1)
        let error = GenerationError.baseGenerationFailed("T", underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("T") ?? false)
    }
    
    func testGenerationErrorOperatorApplicationFailed() {
        let underlying = NSError(domain: "test", code: 1)
        let error = GenerationError.operatorApplicationFailed("d", underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("d") ?? false)
    }
}

