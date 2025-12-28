import XCTest
@testable import PolyhedronismeSwift

final class GenerationEventTests: XCTestCase {
    
    func testGenerationStageParsing() {
        let stage = GenerationStage.parsing
        XCTAssertEqual(stage.description, "parsing")
    }
    
    func testGenerationStageBase() {
        let stage = GenerationStage.base("I")
        XCTAssertEqual(stage.description, "base I")
        
        let stage2 = GenerationStage.base("C")
        XCTAssertEqual(stage2.description, "base C")
    }
    
    func testGenerationStageOperator() {
        let stage = GenerationStage.operator("d")
        XCTAssertEqual(stage.description, "operator d")
        
        let stage2 = GenerationStage.operator("a")
        XCTAssertEqual(stage2.description, "operator a")
    }
    
    func testGenerationStageCanonicalize() {
        let stage = GenerationStage.canonicalize
        XCTAssertEqual(stage.description, "canonicalize")
    }
    
    func testGenerationStageEquatable() {
        let stage1 = GenerationStage.base("I")
        let stage2 = GenerationStage.base("I")
        let stage3 = GenerationStage.base("C")
        
        XCTAssertEqual(stage1, stage2)
        XCTAssertNotEqual(stage1, stage3)
        XCTAssertEqual(GenerationStage.parsing, GenerationStage.parsing)
        XCTAssertEqual(GenerationStage.canonicalize, GenerationStage.canonicalize)
    }
    
    func testPolyhedronMetricsSnapshot() {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 2, 3), Vec3(4, 5, 6)],
            faces: [[0, 1], [1, 0]],
            name: "test",
            faceClasses: []
        )
        
        let snapshot = PolyhedronMetricsSnapshot(model: model, stageDescription: "test stage")
        
        XCTAssertEqual(snapshot.name, "test")
        XCTAssertEqual(snapshot.vertexCount, 2)
        XCTAssertEqual(snapshot.faceCount, 2)
        XCTAssertEqual(snapshot.stageDescription, "test stage")
    }
    
    func testGenerationEventStageStarted() {
        let stage = GenerationStage.base("I")
        let event = GenerationEvent.stageStarted(stage)
        
        if case .stageStarted(let s) = event {
            XCTAssertEqual(s, stage)
        } else {
            XCTFail("Event should be stageStarted")
        }
    }
    
    func testGenerationEventStageCompleted() {
        let stage = GenerationStage.operator("d")
        let event = GenerationEvent.stageCompleted(stage)
        
        if case .stageCompleted(let s) = event {
            XCTAssertEqual(s, stage)
        } else {
            XCTFail("Event should be stageCompleted")
        }
    }
    
    func testGenerationEventMetrics() {
        let model = PolyhedronModel(
            vertices: [Vec3(1, 2, 3)],
            faces: [[0]],
            name: "test",
            faceClasses: []
        )
        let snapshot = PolyhedronMetricsSnapshot(model: model, stageDescription: "test")
        let event = GenerationEvent.metrics(snapshot)
        
        if case .metrics(let s) = event {
            XCTAssertEqual(s.name, "test")
            XCTAssertEqual(s.vertexCount, 1)
            XCTAssertEqual(s.faceCount, 1)
        } else {
            XCTFail("Event should be metrics")
        }
    }
    
    func testGenerationEventCompleted() async throws {
        let cube = try await Polyhedron.cube()
        let event = GenerationEvent.completed(cube)
        
        if case .completed(let p) = event {
            XCTAssertEqual(p.name, "C")
            XCTAssertFalse(p.vertices.isEmpty)
        } else {
            XCTFail("Event should be completed")
        }
    }
}

