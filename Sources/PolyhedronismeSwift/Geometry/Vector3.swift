//
// PolyhedronismeSwift
// Vector3.swift
//
// Vector3 geometric operations and utilities for 3D vectors
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation
import simd

internal enum Vector3 {
    internal static func multiply(_ scalar: Double, _ vec: Vec3) -> Vec3 {
        vec * scalar
    }
    
    internal static func multiply(_ vec1: Vec3, _ vec2: Vec3) -> Vec3 {
        vec1 * vec2
    }
    
    internal static func add(_ vec1: Vec3, _ vec2: Vec3) -> Vec3 {
        vec1 + vec2
    }
    
    internal static func subtract(_ vec1: Vec3, _ vec2: Vec3) -> Vec3 {
        vec1 - vec2
    }
    
    internal static func dot(_ vec1: Vec3, _ vec2: Vec3) -> Double {
        simd_dot(vec1, vec2)
    }
    
    internal static func cross(_ d1: Vec3, _ d2: Vec3) -> Vec3 {
        simd_cross(d1, d2)
    }
    
    internal static func magnitude(_ vec: Vec3) -> Double {
        simd_length(vec)
    }
    
    internal static func magnitudeSquared(_ vec: Vec3) -> Double {
        simd_length_squared(vec)
    }
    
    internal static func normalize(_ vec: Vec3) -> Vec3 {
        let mag = simd_length(vec)
        guard mag > 0 else { return Vec3.zero() }
        return vec / mag
    }
    
    internal static func midpoint(_ vec1: Vec3, _ vec2: Vec3) -> Vec3 {
        (vec1 + vec2) * 0.5
    }
    
    internal static func tween(_ vec1: Vec3, _ vec2: Vec3, _ t: Double) -> Vec3 {
        ((1 - t) * vec1) + (t * vec2)
    }
    
    internal static func oneThird(_ vec1: Vec3, _ vec2: Vec3) -> Vec3 {
        tween(vec1, vec2, 1.0 / 3.0)
    }
    
    internal static func reciprocal(_ vec: Vec3) -> Vec3 {
        let mag2 = simd_length_squared(vec)
        guard mag2 > 0 else { return Vec3.zero() }
        return vec / mag2
    }
}

