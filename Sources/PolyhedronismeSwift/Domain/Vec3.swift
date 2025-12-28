//
// PolyhedronismeSwift
// Vec3.swift
//
// Vec3 domain model for polyhedral operations
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation
import simd

public typealias Vec3 = SIMD3<Double>

extension Vec3 {
    public static func zero() -> Vec3 {
        .zero
    }
    
    public init(_ values: [Double]) {
        precondition(values.count == 3, "Vec3 requires exactly three values")
        self = Vec3(values[0], values[1], values[2])
    }
    
    public func isValid() -> Bool {
        x.isFinite && y.isFinite && z.isFinite
    }
    
    public var count: Int {
        3
    }
    
    public func allSatisfy(_ predicate: (Double) -> Bool) -> Bool {
        predicate(x) && predicate(y) && predicate(z)
    }
    
    public var array: [Double] {
        [x, y, z]
    }
}

