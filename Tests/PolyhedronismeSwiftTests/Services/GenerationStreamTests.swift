import XCTest
@testable import PolyhedronismeSwift

final class GenerationStreamTests: XCTestCase {
    func testStreamEmitsStagesAndCompletes() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        var started: [GenerationStage] = []
        var finished: [GenerationStage] = []
        var metrics: [PolyhedronMetricsSnapshot] = []
        var completed: Polyhedron?
        
        for try await event in generator.stream(recipe: "I") {
            switch event {
            case .stageStarted(let stage):
                started.append(stage)
            case .stageCompleted(let stage):
                finished.append(stage)
            case .metrics(let snapshot):
                metrics.append(snapshot)
            case .completed(let polyhedron):
                completed = polyhedron
            }
        }
        
        XCTAssertEqual(started, [.parsing, .base("I"), .canonicalize])
        XCTAssertEqual(finished.last, .canonicalize)
        XCTAssertFalse(metrics.isEmpty)
        XCTAssertEqual(metrics.last?.faceCount, completed?.faces.count)
        XCTAssertNotNil(completed)
    }
}

