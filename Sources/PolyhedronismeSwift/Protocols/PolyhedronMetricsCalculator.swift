//
// PolyhedronismeSwift
// PolyhedronMetricsCalculator.swift
//
// Protocol definition for PolyhedronMetricsCalculator in polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol PolyhedronMetricsCalculator: Sendable {
    func calculateDataDescription(from model: PolyhedronModel) -> String
    func calculateDetailedDescription(from model: PolyhedronModel, edgeCalculator: EdgeCalculator, faceCalculator: FaceCalculator) async -> String
    func calculateMinEdgeLength(from model: PolyhedronModel, edgeCalculator: EdgeCalculator) async -> Double
    func calculateMinFaceRadius(from model: PolyhedronModel, edgeCalculator: EdgeCalculator, faceCalculator: FaceCalculator) async -> Double
}

