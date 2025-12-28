import XCTest
@testable import PolyhedronismeSwift

final class ParameterExtractorTests: XCTestCase {
    func testExtractIntParameter() async throws {
        let args: [SendableParameter] = [.int(42), .int(100)]
        
        let value = try ParameterExtractor.extractIntParameter(args, at: 0)
        XCTAssertEqual(value, 42)
    }
    
    func testExtractIntParameterWithDefault() async throws {
        let args: [SendableParameter] = []
        
        let value = try ParameterExtractor.extractIntParameter(args, at: 0, default: 10)
        XCTAssertEqual(value, 10)
    }
    
    func testExtractIntParameterMissing() {
        let args: [SendableParameter] = []
        
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractIntParameterWithMin() async throws {
        let args: [SendableParameter] = [.int(5)]
        
        let value = try ParameterExtractor.extractIntParameter(args, at: 0, min: 3)
        XCTAssertEqual(value, 5)
    }
    
    func testExtractIntParameterBelowMin() {
        let args: [SendableParameter] = [.int(2)]
        
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0, min: 3)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractIntParameterWithMax() async throws {
        let args: [SendableParameter] = [.int(5)]
        
        let value = try ParameterExtractor.extractIntParameter(args, at: 0, max: 10)
        XCTAssertEqual(value, 5)
    }
    
    func testExtractIntParameterAboveMax() {
        let args: [SendableParameter] = [.int(15)]
        
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0, max: 10)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractIntParameterWrongType() {
        let args: [SendableParameter] = [.double(42.0)]
        
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractDoubleParameter() async throws {
        let args: [SendableParameter] = [.double(3.14), .double(2.71)]
        
        let value = try ParameterExtractor.extractDoubleParameter(args, at: 0)
        XCTAssertEqual(value, 3.14, accuracy: 1e-10)
    }
    
    func testExtractDoubleParameterWithDefault() async throws {
        let args: [SendableParameter] = []
        
        let value = try ParameterExtractor.extractDoubleParameter(args, at: 0, default: 0.5)
        XCTAssertEqual(value, 0.5, accuracy: 1e-10)
    }
    
    func testExtractDoubleParameterWrongType() {
        let args: [SendableParameter] = [.int(42)]
        
        XCTAssertThrowsError(try ParameterExtractor.extractDoubleParameter(args, at: 0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    

    
    func testExtractDoubleParameterWithMin() async throws {
        let args: [SendableParameter] = [.double(5.0)]
        let value = try ParameterExtractor.extractDoubleParameter(args, at: 0, min: 3.0)
        XCTAssertEqual(value, 5.0, accuracy: 1e-10)
    }
    
    func testExtractDoubleParameterBelowMin() {
        let args: [SendableParameter] = [.double(2.0)]
        XCTAssertThrowsError(try ParameterExtractor.extractDoubleParameter(args, at: 0, min: 3.0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractDoubleParameterAboveMax() {
        let args: [SendableParameter] = [.double(15.0)]
        XCTAssertThrowsError(try ParameterExtractor.extractDoubleParameter(args, at: 0, max: 10.0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractDoubleParameterWithBothMinAndMax() async throws {
        let args: [SendableParameter] = [.double(5.0)]
        let value = try ParameterExtractor.extractDoubleParameter(args, at: 0, min: 3.0, max: 10.0)
        XCTAssertEqual(value, 5.0, accuracy: 1e-10)
    }
    
    func testExtractDoubleParameterWithBothMinAndMaxOutOfRange() {
        let args: [SendableParameter] = [.double(15.0)]
        XCTAssertThrowsError(try ParameterExtractor.extractDoubleParameter(args, at: 0, min: 3.0, max: 10.0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractIntParameterWithBothMinAndMax() async throws {
        let args: [SendableParameter] = [.int(5)]
        let value = try ParameterExtractor.extractIntParameter(args, at: 0, min: 3, max: 10)
        XCTAssertEqual(value, 5)
    }
    
    func testExtractIntParameterWithBothMinAndMaxOutOfRange() {
        let args: [SendableParameter] = [.int(15)]
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0, min: 3, max: 10)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractIntParameterWithCustomParameterName() {
        let args: [SendableParameter] = []
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0, parameterName: "custom param")) { error in
            if let parseError = error as? ParseError {
                XCTAssertTrue(parseError.localizedDescription.contains("custom param"))
            } else {
                XCTFail("Expected ParseError")
            }
        }
    }
    
    func testExtractIntParameterWithStringType() {
        let args: [SendableParameter] = [.string("test")]
        XCTAssertThrowsError(try ParameterExtractor.extractIntParameter(args, at: 0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractDoubleParameterWithStringType() {
        let args: [SendableParameter] = [.string("test")]
        XCTAssertThrowsError(try ParameterExtractor.extractDoubleParameter(args, at: 0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
    
    func testExtractDoubleParameterMissing() {
        let args: [SendableParameter] = []
        XCTAssertThrowsError(try ParameterExtractor.extractDoubleParameter(args, at: 0)) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
}

