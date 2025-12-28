import XCTest
@testable import PolyhedronismeSwift

final class CanonicalizationPipelineTests: XCTestCase {
    func testReciprocalC() async {
        let vertices: [Vec3] = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]
        let pipeline = CanonicalizationPipelineActor(enableMetal: false)
        let stage = await pipeline.reciprocalC(vertices: ContiguousArray(vertices))
        let expected = CanonicalizationMath.reciprocalC(vertices: ContiguousArray(vertices))
        
        XCTAssertEqual(stage.values.count, expected.count)
        for i in 0..<expected.count {
            XCTAssertEqual(stage.values[i], expected[i])
        }
    }
    
    func testReciprocalN() async {
        let vertices: [Vec3] = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]
        let faces: [Face] = [
            [0, 1, 2],
            [1, 2, 0],
            [2, 0, 1]
        ]
        let pipeline = CanonicalizationPipelineActor(enableMetal: false)
        let stage = await pipeline.reciprocalN(vertices: ContiguousArray(vertices), faces: faces)
        let expected = CanonicalizationMath.reciprocalN(vertices: ContiguousArray(vertices), faces: faces)
        XCTAssertEqual(stage.values.count, expected.count)
        for (lhs, rhs) in zip(stage.values, expected) {
            assertEqual(lhs, rhs, accuracy: 1e-9)
        }
    }
    
    private func assertEqual(
        _ lhs: Vec3,
        _ rhs: Vec3,
        accuracy: Double = 1e-9,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.x, rhs.x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.y, rhs.y, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.z, rhs.z, accuracy: accuracy, file: file, line: line)
    }
}

