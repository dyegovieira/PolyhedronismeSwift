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

    func testStreamAllowsEarlyConsumerExit() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        var receivedEvents = 0

        for try await _ in generator.stream(recipe: "u5I") {
            receivedEvents += 1
            break
        }

        XCTAssertEqual(receivedEvents, 1)
    }

    func testCancelledConsumerDoesNotReceiveCompletion() async throws {
        let generator = PolyhedronismeSwiftGenerator()
        let consumer = Task { () throws -> Bool in
            for try await event in generator.stream(recipe: "u10I") {
                if case .completed = event {
                    return true
                }
                try Task.checkCancellation()
            }
            return false
        }

        try await Task.sleep(for: .milliseconds(1))
        consumer.cancel()

        do {
            let receivedCompletion = try await consumer.value
            XCTAssertFalse(receivedCompletion)
        } catch is CancellationError {
            // Expected: stream termination cancels its producer and the consumer.
        }
    }

    func testGenerationFailureFinishesWithoutCompletion() async {
        let generator = PolyhedronismeSwiftGenerator()
        var completed = false

        do {
            for try await event in generator.stream(recipe: "X") {
                if case .completed = event {
                    completed = true
                }
            }
            XCTFail("Expected generation failure")
        } catch let error as GenerationError {
            if case .parsingFailed(.unknownBase("X")) = error {
                // Expected original mapped error.
            } else {
                XCTFail("Unexpected generation error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertFalse(completed)
    }
}
