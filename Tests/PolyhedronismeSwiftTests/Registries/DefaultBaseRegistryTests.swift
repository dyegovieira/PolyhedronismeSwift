import XCTest
@testable import PolyhedronismeSwift

final class DefaultBaseRegistryTests: XCTestCase {
    func testGetBase() {
        let tetra = TetrahedronGenerator()
        let registry = DefaultBaseRegistry(
            bases: ["T": tetra],
            parameterizedBases: [:]
        )
        
        let retrieved = registry.getBase(for: "T")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.identifier, "T")
    }
    
    func testGetBaseNotFound() {
        let registry = DefaultBaseRegistry()
        let retrieved = registry.getBase(for: "X")
        XCTAssertNil(retrieved)
    }
    
    func testGetParameterizedBase() {
        let prism = PrismGenerator()
        let registry = DefaultBaseRegistry(
            bases: [:],
            parameterizedBases: ["P": prism]
        )
        
        let retrieved = registry.getParameterizedBase(for: "P", as: PrismParameters.self)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.identifier, "P")
    }
    
    func testAllBases() {
        let tetra = TetrahedronGenerator()
        let cube = CubeGenerator()
        let registry = DefaultBaseRegistry(
            bases: ["T": tetra, "C": cube],
            parameterizedBases: [:]
        )
        
        let all = registry.allBases()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all["T"]?.identifier, "T")
        XCTAssertEqual(all["C"]?.identifier, "C")
    }
}

