import XCTest
import PolyhedronismeSwift

final class PolyhedronismeSwiftPublicClientTests: XCTestCase {
    func testPublicClientCanGenerateAndStream() async throws {
        let generator = PolyhedronismeSwiftGenerator(
            parallelismConfiguration: ParallelismConfiguration(
                parallelismEnabled: false,
                maxParallelTasks: 1,
                minParallelWorkload: 1
            )
        )

        let generated = try await generator.generate(recipe: "I")
        XCTAssertEqual(generated.recipe, "I")
        XCTAssertFalse(generated.vertices.isEmpty)
        XCTAssertFalse(generated.faces.isEmpty)

        var completed: Polyhedron?
        for try await event in generator.stream(recipe: "I") {
            if case .completed(let polyhedron) = event {
                completed = polyhedron
            }
        }

        XCTAssertEqual(completed?.recipe, generated.recipe)
        XCTAssertEqual(completed?.faces, generated.faces)
        XCTAssertEqual(completed?.vertices.count, generated.vertices.count)

        let streamedVertices = try XCTUnwrap(completed?.vertices)
        for (lhs, rhs) in zip(streamedVertices, generated.vertices) {
            XCTAssertEqual(lhs.x, rhs.x, accuracy: 1e-12)
            XCTAssertEqual(lhs.y, rhs.y, accuracy: 1e-12)
            XCTAssertEqual(lhs.z, rhs.z, accuracy: 1e-12)
        }
    }

    func testPublicMetalErrorRemainsFrameworkNeutral() {
        let error = MetalError.commandFailure("device lost")
        XCTAssertEqual(error.errorDescription, "Metal command failed: device lost")
    }
}
