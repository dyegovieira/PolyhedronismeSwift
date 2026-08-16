import XCTest
@testable import PolyhedronismeSwift

final class DefaultOperatorFactoryTests: XCTestCase {
    private func makeFactory() -> DefaultOperatorFactory {
        DefaultOperatorFactory(
            operatorRegistry: StandardOperatorRegistry.makeDefault(),
            metalExecutor: MetalExecutor(capabilities: .unavailable)
        )
    }

    func testCreatesBuiltInOperatorsThroughValueOnlyExecutor() async throws {
        let factory = makeFactory()
        for operation in [
            OperatorOperation(identifier: "k", parameters: []),
            OperatorOperation(identifier: "r", parameters: []),
            OperatorOperation(identifier: "d", parameters: []),
            OperatorOperation(identifier: "a", parameters: []),
            OperatorOperation(identifier: "u", parameters: [])
        ] {
            let createdOperator = try await factory.createOperator(for: operation)
            XCTAssertNotNil(createdOperator)
        }
    }

    func testCreatesParameterizedOperators() async throws {
        let factory = makeFactory()
        let kisOperator = try await factory.createOperator(for: OperatorOperation(
            identifier: "k", parameters: [.int(4), .double(0.3)]
        ))
        XCTAssertNotNil(kisOperator)
        let trisubOperator = try await factory.createOperator(for: OperatorOperation(
            identifier: "u", parameters: [.int(3)]
        ))
        XCTAssertNotNil(trisubOperator)
    }

    func testUnknownOperatorThrowsGenerationError() async {
        do {
            _ = try await makeFactory().createOperator(for: OperatorOperation(identifier: "?", parameters: []))
            XCTFail("Unknown operator must fail")
        } catch is GenerationError {
            // Expected.
        } catch {
            XCTFail("Expected GenerationError, got \(error)")
        }
    }
}
