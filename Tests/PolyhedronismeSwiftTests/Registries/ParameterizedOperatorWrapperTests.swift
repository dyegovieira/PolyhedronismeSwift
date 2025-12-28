import XCTest
@testable import PolyhedronismeSwift

final class ParameterizedOperatorWrapperTests: XCTestCase {
    func testIdentifier() {
        let kisOp = KisOperator()
        let params = KisParameters(n: 3, apexDistance: 0.1)
        let wrapper = ParameterizedOperatorWrapper(kisOp, withDefaultParameters: params)
        
        XCTAssertEqual(wrapper.identifier, "k")
    }
    
    func testApply() async throws {
        let kisOp = KisOperator()
        let params = KisParameters(n: 3, apexDistance: 0.1)
        let wrapper = ParameterizedOperatorWrapper(kisOp, withDefaultParameters: params)
        
        let tetrahedron = try await TetrahedronGenerator().generate()
        let result = try await wrapper.apply(to: tetrahedron)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testApplyWithTrisubOperator() async throws {
        let trisubOp = TrisubOperator()
        let params = TrisubParameters(n: 2)
        let wrapper = ParameterizedOperatorWrapper(trisubOp, withDefaultParameters: params)
        
        let tetrahedron = try await TetrahedronGenerator().generate()
        let result = try await wrapper.apply(to: tetrahedron)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testApplyWithDefaultParameters() async throws {
        let kisOp = KisOperator()
        let params = KisParameters()
        let wrapper = ParameterizedOperatorWrapper(kisOp, withDefaultParameters: params)
        
        let cube = try await CubeGenerator().generate()
        let result = try await wrapper.apply(to: cube)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(wrapper.identifier, "k")
    }
    
    func testApplyPreservesOperatorBehavior() async throws {
        let trisubOp = TrisubOperator()
        let params = TrisubParameters(n: 3)
        let wrapper = ParameterizedOperatorWrapper(trisubOp, withDefaultParameters: params)
        
        let tetrahedron = try await TetrahedronGenerator().generate()
        let directResult = try await trisubOp.apply(to: tetrahedron, parameters: params)
        let wrappedResult = try await wrapper.apply(to: tetrahedron)
        
        XCTAssertEqual(directResult.vertices.count, wrappedResult.vertices.count)
        XCTAssertEqual(directResult.faces.count, wrappedResult.faces.count)
    }
}

