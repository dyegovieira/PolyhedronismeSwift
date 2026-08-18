import PolyhedronismeSwift
import XCTest

final class PublicClientSurfaceTests: XCTestCase {
    func testGeneratorPublicSurfaceCompilesAndRuns() async throws {
        let generator = PolyhedronismeSwiftGenerator(
            parallelismConfiguration: ParallelismConfiguration(
                parallelismEnabled: false,
                maxParallelTasks: 1,
                minParallelWorkload: 1
            )
        )

        let polyhedron = try await generator.generate(recipe: "T")

        XCTAssertEqual(polyhedron.name, "T")
        XCTAssertEqual(polyhedron.vertices.count, 4)
        XCTAssertEqual(polyhedron.faces.count, 4)
        XCTAssertEqual(polyhedron.recipe, "T")
    }

    func testStreamPublicSurfaceCompiles() {
        let generator = PolyhedronismeSwiftGenerator()
        let stream = generator.stream(recipe: "T")

        _ = stream
    }

    func testCorePublicValuesCompile() {
        let face: Face = [0, 1, 2]
        let polyhedron = Polyhedron(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faces: [face],
            name: "Triangle",
            faceClasses: [0],
            recipe: "T"
        )

        XCTAssertEqual(polyhedron.faces.first, face)
        XCTAssertTrue(face.isValid(vertexCount: polyhedron.vertices.count))
        XCTAssertFalse(face.hasDuplicates())
    }
}
