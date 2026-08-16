import XCTest
@testable import PolyhedronismeSwift

final class MetalExecutorTests: XCTestCase {
    func testCompletionStateKeepsFirstTerminalResultForLateCallbacks() async {
        let state = MetalExecutorCompletionState()

        await state.finish(.failed(.timeout))
        await state.finish(.succeeded)
        let result = await state.wait()

        guard case .failed(.timeout) = result else {
            return XCTFail("The first completion must win")
        }
    }

    func testCompletionStateResumesWaitingConsumerExactlyOnce() async {
        let state = MetalExecutorCompletionState()
        async let result = state.wait()

        await state.finish(.cancelled)
        await state.finish(.succeeded)

        guard case .cancelled = await result else {
            return XCTFail("Cancellation must remain the terminal result")
        }
    }

    func testInjectedAvailableCapabilitiesAreReturnedAsValue() async {
        let executor = MetalExecutor(capabilities: MetalCapabilities(isAvailable: true))

        let capabilities = await executor.capabilities()

        XCTAssertEqual(capabilities, MetalCapabilities(isAvailable: true))
    }

    func testInjectedUnavailableCapabilitiesAreReturnedAsValue() async {
        let executor = MetalExecutor(capabilities: .unavailable)

        let capabilities = await executor.capabilities()

        XCTAssertEqual(capabilities, .unavailable)
    }

    func testReflectWithoutOwnedMetalStateThrowsAvailabilityError() async {
        let executor = MetalExecutor(capabilities: .unavailable)

        do {
            _ = try await executor.reflect(MetalReflectRequest(vertices: [Vec3(1, 2, 3)]))
            XCTFail("Unavailable Metal must not produce a result")
        } catch let error as MetalError {
            XCTAssertEqual(error.localizedDescription, MetalError.deviceNotFound.localizedDescription)
        } catch {
            XCTFail("Expected MetalError, got \(error)")
        }
    }

    func testAmboWithoutOwnedMetalStateThrowsAvailabilityError() async {
        let executor = MetalExecutor(capabilities: .unavailable)
        let request = MetalAmboRequest(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0)],
            edges: [MetalAmboEdge(v1: 0, v2: 1)]
        )

        do {
            _ = try await executor.ambo(request)
            XCTFail("Unavailable Metal must not produce a result")
        } catch let error as MetalError {
            XCTAssertEqual(error.localizedDescription, MetalError.deviceNotFound.localizedDescription)
        } catch {
            XCTFail("Expected MetalError, got \(error)")
        }
    }

    func testKisWithoutOwnedMetalStateThrowsAvailabilityError() async {
        let executor = MetalExecutor(capabilities: .unavailable)
        let request = MetalKisRequest(
            vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
            faceInfos: [FaceInfo(start: 0, count: 3)],
            faceIndices: [0, 1, 2],
            parameters: KisParameters(n: 0, apexDistance: 0.1)
        )

        do {
            _ = try await executor.kis(request)
            XCTFail("Unavailable Metal must not produce a result")
        } catch let error as MetalError {
            XCTAssertEqual(error.localizedDescription, MetalError.deviceNotFound.localizedDescription)
        } catch {
            XCTFail("Expected MetalError, got \(error)")
        }
    }

    func testCanonicalizationWithoutOwnedMetalStateThrowsAvailabilityError() async {
        let executor = MetalExecutor(capabilities: .unavailable)

        do {
            _ = try await executor.reciprocalC(
                MetalReciprocalCRequest(vertices: [Vec3(1, 2, 3)])
            )
            XCTFail("Unavailable Metal must not produce a result")
        } catch let error as MetalError {
            XCTAssertEqual(
                error.localizedDescription,
                MetalError.unavailable(capability: "canonicalization").localizedDescription
            )
        } catch {
            XCTFail("Expected MetalError, got \(error)")
        }
    }

    func testDualWithoutOwnedMetalStateThrowsAvailabilityError() async {
        let executor = MetalExecutor(capabilities: .unavailable)

        do {
            _ = try await executor.dual(
                MetalDualRequest(
                    vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
                    faces: [[0, 1, 2]]
                )
            )
            XCTFail("Unavailable Metal must not produce a result")
        } catch let error as MetalError {
            XCTAssertEqual(
                error.localizedDescription,
                MetalError.unavailable(capability: "dual").localizedDescription
            )
        } catch {
            XCTFail("Expected MetalError, got \(error)")
        }
    }
}
