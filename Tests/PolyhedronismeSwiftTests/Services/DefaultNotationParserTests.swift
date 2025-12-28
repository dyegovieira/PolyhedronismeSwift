import XCTest
@testable import PolyhedronismeSwift

final class DefaultNotationParserTests: XCTestCase {
    private let parser = DefaultNotationParser()
    
    func testParseSimpleBase() async throws {
        let ast = try parser.parse("I")
        
        XCTAssertEqual(ast.base.identifier, "I")
        XCTAssertTrue(ast.operators.isEmpty)
    }
    
    func testParseWithOperator() async throws {
        let ast = try parser.parse("dI")
        
        XCTAssertEqual(ast.base.identifier, "I")
        XCTAssertEqual(ast.operators.count, 1)
        XCTAssertEqual(ast.operators[0].identifier, "d")
    }
    
    func testParseMultipleOperators() async throws {
        let ast = try parser.parse("adI")
        
        XCTAssertEqual(ast.base.identifier, "D")
        XCTAssertEqual(ast.operators.count, 1)
        XCTAssertEqual(ast.operators[0].identifier, "a")
    }
    
    func testParseWithParameters() async throws {
        let ast = try parser.parse("k3I")
        
        XCTAssertEqual(ast.base.identifier, "I")
        XCTAssertEqual(ast.operators.count, 1)
        XCTAssertEqual(ast.operators[0].identifier, "k")
        XCTAssertEqual(ast.operators[0].parameters.count, 1)
        if case .int(let n) = ast.operators[0].parameters[0] {
            XCTAssertEqual(n, 3)
        } else {
            XCTFail("Expected int parameter")
        }
    }
    
    func testParseEmptyNotation() {
        XCTAssertThrowsError(try parser.parse("")) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testSpecialReplacements() async throws {
        let ast = try parser.parse("eI")
        XCTAssertEqual(ast.operators.count, 2)
        XCTAssertEqual(ast.operators[0].identifier, "a")
        XCTAssertEqual(ast.operators[1].identifier, "a")
    }
    
    func testParseWithWhitespace() async throws {
        let ast = try parser.parse("d I")
        XCTAssertEqual(ast.base.identifier, "I")
        XCTAssertEqual(ast.operators.count, 1)
        XCTAssertEqual(ast.operators[0].identifier, "d")
    }
    
    func testParseWithMultipleWhitespace() async throws {
        let ast = try parser.parse("  d  I  ")
        XCTAssertEqual(ast.base.identifier, "I")
        XCTAssertEqual(ast.operators.count, 1)
        XCTAssertEqual(ast.operators[0].identifier, "d")
    }
    
    func testParseErrorInvalidRegexPattern() {
        let error = ParseError.invalidRegexPattern("test pattern", underlying: NSError(domain: "test", code: 1))
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("test pattern") ?? false)
    }
}

