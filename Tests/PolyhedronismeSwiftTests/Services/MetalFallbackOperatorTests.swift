import XCTest
@testable import PolyhedronismeSwift

final class MetalFallbackOperatorTests: XCTestCase {
    
    func testFallbackToCPUWhenMetalThrowsMetalError() async throws {
        let cube = try await CubeGenerator().generate()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let cpuOperator = ReflectOperator()
        let failingMetalOperator = FailingMetalOperator()
        
        let fallbackOperator = MetalFallbackOperator(
            metalOperator: failingMetalOperator,
            cpuFallback: cpuOperator
        )
        
        let result = try await fallbackOperator.apply(to: model)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
        XCTAssertEqual(result.name, "rC")
    }
    
    func testNonMetalErrorsPropagate() async throws {
        let cube = try await CubeGenerator().generate()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let cpuOperator = ReflectOperator()
        let throwingOperator = ThrowingNonMetalOperator()
        
        let fallbackOperator = MetalFallbackOperator(
            metalOperator: throwingOperator,
            cpuFallback: cpuOperator
        )
        
        do {
            _ = try await fallbackOperator.apply(to: model)
            XCTFail("Should propagate non-Metal errors")
        } catch {
            XCTAssertFalse(error is MetalError, "Non-Metal errors should propagate")
        }
    }

    func testCancellationNeverFallsBackToCPU() async throws {
        let cube = try await CubeGenerator().generate()
        let model = PolyhedronModel(vertices: cube.vertices, faces: cube.faces, name: "C", faceClasses: [])
        let fallbackRecorder = OperatorInvocationRecorder()
        let fallbackOperator = MetalFallbackOperator(
            metalOperator: CancelledMetalOperator(),
            cpuFallback: RecordingCPUOperator(recorder: fallbackRecorder)
        )

        do {
            _ = try await fallbackOperator.apply(to: model)
            XCTFail("Cancellation must not use the CPU fallback")
        } catch is CancellationError {
            // Expected.
        }

        let invocationCount = await fallbackRecorder.invocationCount()
        XCTAssertEqual(invocationCount, 0)
    }
    
    func testParameterizedFallbackToCPUWhenMetalThrowsMetalError() async throws {
        let cube = try await CubeGenerator().generate()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let cpuOperator = KisOperator()
        let failingMetalOperator = FailingParameterizedMetalOperator()
        let parameters = KisParameters(n: 0, apexDistance: 0.2)
        
        let fallbackOperator = MetalFallbackParameterizedOperator(
            metalOperator: failingMetalOperator,
            cpuFallback: cpuOperator,
            parameters: parameters
        )
        
        let result = try await fallbackOperator.apply(to: model)
        
        XCTAssertFalse(result.vertices.isEmpty)
        XCTAssertFalse(result.faces.isEmpty)
    }
    
    func testParameterizedFallbackNonMetalErrorsPropagate() async throws {
        let cube = try await CubeGenerator().generate()
        let model = PolyhedronModel(
            vertices: cube.vertices,
            faces: cube.faces,
            name: "C",
            faceClasses: []
        )
        
        let cpuOperator = KisOperator()
        let throwingOperator = ThrowingParameterizedNonMetalOperator()
        let parameters = KisParameters(n: 0, apexDistance: 0.2)
        
        let fallbackOperator = MetalFallbackParameterizedOperator(
            metalOperator: throwingOperator,
            cpuFallback: cpuOperator,
            parameters: parameters
        )
        
        do {
            _ = try await fallbackOperator.apply(to: model)
            XCTFail("Should propagate non-Metal errors")
        } catch {
            XCTAssertFalse(error is MetalError, "Non-Metal errors should propagate")
        }
    }
}

private actor OperatorInvocationRecorder {
    private var count = 0

    func recordInvocation() {
        count += 1
    }

    func invocationCount() -> Int {
        count
    }
}

private struct RecordingCPUOperator: PolyhedronOperator {
    let identifier = "recording-cpu"
    let recorder: OperatorInvocationRecorder

    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        await recorder.recordInvocation()
        return polyhedron
    }
}

private struct FailingMetalOperator: PolyhedronOperator {
    let identifier: String = "test"
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        throw MetalError.deviceNotFound
    }
}

private struct ThrowingNonMetalOperator: PolyhedronOperator {
    let identifier: String = "test"
    
    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        throw NSError(domain: "TestError", code: 1)
    }
}

private struct CancelledMetalOperator: PolyhedronOperator {
    let identifier: String = "test"

    func apply(to polyhedron: PolyhedronModel) async throws -> PolyhedronModel {
        throw CancellationError()
    }
}

private struct FailingParameterizedMetalOperator: ParameterizedPolyhedronOperator {
    typealias Parameters = KisParameters
    
    let identifier: String = "test"
    
    func apply(to polyhedron: PolyhedronModel, parameters: KisParameters) async throws -> PolyhedronModel {
        throw MetalError.deviceNotFound
    }
}

private struct ThrowingParameterizedNonMetalOperator: ParameterizedPolyhedronOperator {
    typealias Parameters = KisParameters
    
    let identifier: String = "test"
    
    func apply(to polyhedron: PolyhedronModel, parameters: KisParameters) async throws -> PolyhedronModel {
        throw NSError(domain: "TestError", code: 1)
    }
}
