import XCTest
@testable import PolyhedronismeSwift

final class DefaultOperatorRegistryTests: XCTestCase {
    func testGetOperator() {
        let ambo = AmboOperator()
        let registry = DefaultOperatorRegistry(operators: ["a": ambo])
        
        let retrieved = registry.getOperator(for: "a")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.identifier, "a")
    }
    
    func testGetOperatorNotFound() {
        let registry = DefaultOperatorRegistry()
        let retrieved = registry.getOperator(for: "x")
        XCTAssertNil(retrieved)
    }
    
    func testAllOperators() {
        let ambo = AmboOperator()
        let dual = DualOperator()
        let registry = DefaultOperatorRegistry(operators: ["a": ambo, "d": dual])
        
        let all = registry.allOperators()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all["a"]?.identifier, "a")
        XCTAssertEqual(all["d"]?.identifier, "d")
    }
}

