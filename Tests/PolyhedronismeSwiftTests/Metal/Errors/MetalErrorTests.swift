import XCTest
@testable import PolyhedronismeSwift

final class MetalErrorTests: XCTestCase {
    
    func testDeviceNotFoundError() {
        let error = MetalError.deviceNotFound
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "Metal device not found")
    }
    
    func testLibraryNotFoundError() {
        let error = MetalError.libraryNotFound
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "Metal library not found")
    }
    
    func testFunctionNotFoundError() {
        let functionName = "test_kernel"
        let error = MetalError.functionNotFound(functionName)
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "Metal function '\(functionName)' not found")
        XCTAssertTrue(error.errorDescription?.contains(functionName) ?? false)
    }
    
    func testFunctionNotFoundErrorWithDifferentName() {
        let functionName = "ambo_vertex_kernel"
        let error = MetalError.functionNotFound(functionName)
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "Metal function '\(functionName)' not found")
    }
    
    func testMetalErrorIsSendable() {
        let error: MetalError = .deviceNotFound
        let sendableError: any Error & Sendable = error
        XCTAssertNotNil(sendableError)
    }
    
    func testMetalErrorIsLocalizedError() {
        let error: MetalError = .libraryNotFound
        let localizedError: LocalizedError = error
        XCTAssertNotNil(localizedError.errorDescription)
    }
}

