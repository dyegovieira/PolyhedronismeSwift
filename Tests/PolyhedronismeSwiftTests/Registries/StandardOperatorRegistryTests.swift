import XCTest
@testable import PolyhedronismeSwift

final class StandardOperatorRegistryTests: XCTestCase {
    func testMakeDefault() {
        let registry = StandardOperatorRegistry.makeDefault()
        
        XCTAssertNotNil(registry.getOperator(for: "r"))
        XCTAssertNotNil(registry.getOperator(for: "d"))
        XCTAssertNotNil(registry.getOperator(for: "a"))
        XCTAssertNotNil(registry.getOperator(for: "g"))
        XCTAssertNotNil(registry.getOperator(for: "p"))
        XCTAssertNotNil(registry.getOperator(for: "k"))
        XCTAssertNotNil(registry.getOperator(for: "u"))
    }
    
    func testParameterizedOperators() {
        let registry = StandardOperatorRegistry.makeDefault()
        
        let kisOp = registry.getOperator(for: "k")
        XCTAssertNotNil(kisOp)
        
        let trisubOp = registry.getOperator(for: "u")
        XCTAssertNotNil(trisubOp)
    }
}

