//
// PolyhedronismeSwift
// FaceCalculator.swift
//
// Protocol definition for FaceCalculator in polyhedral calculations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal protocol FaceCalculator: Sendable {
    func calculateCenters(from polyhedron: PolyhedronModel) async -> [Vec3]
    func calculateNormals(from polyhedron: PolyhedronModel) async -> [Vec3]
}

