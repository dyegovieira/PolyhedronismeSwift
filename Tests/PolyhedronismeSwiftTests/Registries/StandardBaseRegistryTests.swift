import XCTest
@testable import PolyhedronismeSwift

final class StandardBaseRegistryTests: XCTestCase {
    func testMakeDefault() {
        let registry = StandardBaseRegistry.makeDefault()
        
        XCTAssertNotNil(registry.getBase(for: "T"))
        XCTAssertNotNil(registry.getBase(for: "O"))
        XCTAssertNotNil(registry.getBase(for: "C"))
        XCTAssertNotNil(registry.getBase(for: "I"))
        XCTAssertNotNil(registry.getBase(for: "D"))
        
        XCTAssertNotNil(registry.getParameterizedBase(for: "P", as: PrismParameters.self))
        XCTAssertNotNil(registry.getParameterizedBase(for: "A", as: AntiprismParameters.self))
        XCTAssertNotNil(registry.getParameterizedBase(for: "Y", as: PyramidParameters.self))
        XCTAssertNotNil(registry.getParameterizedBase(for: "U", as: CupolaParameters.self))
        XCTAssertNotNil(registry.getParameterizedBase(for: "V", as: AnticupolaParameters.self))
    }
}

