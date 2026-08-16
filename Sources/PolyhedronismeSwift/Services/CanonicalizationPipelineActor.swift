//
// CanonicalizationPipelineActor.swift
//
// Coordinates canonicalization stages while keeping all Metal state inside
// MetalExecutor. This actor transfers only geometry values across its boundary.
//

import Foundation
import os

typealias OSLogger = os.Logger

enum CanonicalizationStage: Sendable, Equatable {
    case reciprocalC
    case reciprocalN
}

struct CanonicalizationTelemetry: Sendable {
    let stage: CanonicalizationStage
    let duration: TimeInterval
    let usedGPU: Bool
}

struct CanonicalizationStageResult: Sendable {
    let values: ContiguousArray<Vec3>
    let telemetry: CanonicalizationTelemetry

    func asArray() -> [Vec3] { Array(values) }
}

actor CanonicalizationPipelineActor {
    private let enableMetal: Bool
    private let logger = OSLogger(subsystem: "PolyhedronismeSwift", category: "CanonicalizationPipeline")
    private let metalExecutor: MetalExecutor?

    init(enableMetal: Bool = true) {
        self.enableMetal = enableMetal
        self.metalExecutor = enableMetal ? MetalExecutor() : nil
    }

    /// Test seam that keeps the dependency value-only at this actor boundary.
    internal init(executor: MetalExecutor, enableMetal: Bool = true) {
        self.enableMetal = enableMetal
        self.metalExecutor = enableMetal ? executor : nil
    }

    func reciprocalC(vertices: ContiguousArray<Vec3>) async -> CanonicalizationStageResult {
        let start = ContinuousClock.now
        if enableMetal, !vertices.isEmpty, let metalExecutor {
            do {
                let result = try await metalExecutor.reciprocalC(
                    MetalReciprocalCRequest(vertices: Array(vertices))
                )
                let duration = start.elapsedTime()
                logger.debug("reciprocalC GPU completed in \(duration, privacy: .public)s")
                return CanonicalizationStageResult(
                    values: ContiguousArray(result.vertices),
                    telemetry: CanonicalizationTelemetry(stage: .reciprocalC, duration: duration, usedGPU: true)
                )
            } catch is CancellationError {
                // This legacy non-throwing API cannot surface cancellation. The
                // enclosing generator checks cancellation at its stage boundary.
            } catch {
                // Metal availability and execution failures recover via CPU.
            }
        }

        let fallback = CanonicalizationMath.reciprocalC(vertices: vertices)
        let duration = start.elapsedTime()
        logger.debug("reciprocalC CPU fallback completed in \(duration, privacy: .public)s")
        return CanonicalizationStageResult(
            values: fallback,
            telemetry: CanonicalizationTelemetry(stage: .reciprocalC, duration: duration, usedGPU: false)
        )
    }

    func reciprocalN(vertices: ContiguousArray<Vec3>, faces: [Face]) async -> CanonicalizationStageResult {
        let start = ContinuousClock.now
        if enableMetal, !vertices.isEmpty, !faces.isEmpty, let metalExecutor {
            do {
                let result = try await metalExecutor.reciprocalN(
                    MetalReciprocalNRequest(vertices: Array(vertices), faces: faces)
                )
                let duration = start.elapsedTime()
                logger.debug("reciprocalN GPU completed in \(duration, privacy: .public)s")
                return CanonicalizationStageResult(
                    values: ContiguousArray(result.vertices),
                    telemetry: CanonicalizationTelemetry(stage: .reciprocalN, duration: duration, usedGPU: true)
                )
            } catch is CancellationError {
                // See reciprocalC.
            } catch {
                // Metal availability and execution failures recover via CPU.
            }
        }

        let fallback = CanonicalizationMath.reciprocalN(vertices: vertices, faces: faces)
        let duration = start.elapsedTime()
        logger.debug("reciprocalN CPU fallback completed in \(duration, privacy: .public)s")
        return CanonicalizationStageResult(
            values: fallback,
            telemetry: CanonicalizationTelemetry(stage: .reciprocalN, duration: duration, usedGPU: false)
        )
    }
}

private extension ContinuousClock.Instant {
    func elapsedTime() -> TimeInterval {
        let duration = self.duration(to: ContinuousClock.now)
        let seconds = Double(duration.components.seconds)
        let attoseconds = Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
        return seconds + attoseconds
    }
}
