//
// PolyhedronismeSwift
// Matrix3.swift
//
// Matrix3 geometric operations and utilities for 3x3 matrices
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal typealias Matrix3 = [[Double]]

internal enum Matrix3Operations {
    internal static let identity: Matrix3 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
    
    internal static func multiplyVector(_ mat: Matrix3, _ vec: Vec3) -> Vec3 {
        [
            (mat[0][0] * vec[0]) + (mat[0][1] * vec[1]) + (mat[0][2] * vec[2]),
            (mat[1][0] * vec[0]) + (mat[1][1] * vec[1]) + (mat[1][2] * vec[2]),
            (mat[2][0] * vec[0]) + (mat[2][1] * vec[1]) + (mat[2][2] * vec[2])
        ]
    }
    
    internal static func multiply(_ A: Matrix3, _ B: Matrix3) -> Matrix3 {
        [
            [
                (A[0][0] * B[0][0]) + (A[0][1] * B[1][0]) + (A[0][2] * B[2][0]),
                (A[0][0] * B[0][1]) + (A[0][1] * B[1][1]) + (A[0][2] * B[2][1]),
                (A[0][0] * B[0][2]) + (A[0][1] * B[1][2]) + (A[0][2] * B[2][2])
            ],
            [
                (A[1][0] * B[0][0]) + (A[1][1] * B[1][0]) + (A[1][2] * B[2][0]),
                (A[1][0] * B[0][1]) + (A[1][1] * B[1][1]) + (A[1][2] * B[2][1]),
                (A[1][0] * B[0][2]) + (A[1][1] * B[1][2]) + (A[1][2] * B[2][2])
            ],
            [
                (A[2][0] * B[0][0]) + (A[2][1] * B[1][0]) + (A[2][2] * B[2][0]),
                (A[2][0] * B[0][1]) + (A[2][1] * B[1][1]) + (A[2][2] * B[2][1]),
                (A[2][0] * B[0][2]) + (A[2][1] * B[1][2]) + (A[2][2] * B[2][2])
            ]
        ]
    }
    
    internal static func rotationMatrix(phi: Double, theta: Double, psi: Double) -> Matrix3 {
        let xyMat = [
            [cos(phi), -1.0 * sin(phi), 0.0],
            [sin(phi), cos(phi), 0.0],
            [0.0, 0.0, 1.0]
        ]
        let yzMat = [
            [cos(theta), 0, -1.0 * sin(theta)],
            [0, 1, 0],
            [sin(theta), 0, cos(theta)]
        ]
        let xzMat = [
            [1.0, 0, 0],
            [0, cos(psi), -1.0 * sin(psi)],
            [0, sin(psi), cos(psi)]
        ]
        return multiply(xzMat, multiply(yzMat, xyMat))
    }
    
    internal static func rotationMatrix(angle: Double, axisX: Double, axisY: Double, axisZ: Double) -> Matrix3 {
        let halfAngle = angle / 2.0
        let sinA = sin(halfAngle)
        let cosA = cos(halfAngle)
        let sinA2 = sinA * sinA
        
        var x = axisX
        var y = axisY
        var z = axisZ
        let length = Vector3.magnitude([x, y, z])
        
        if length == 0 {
            // Zero axis means no rotation - return identity matrix
            return identity
        }
        if length != 1 {
            let u = Vector3.normalize([x, y, z])
            x = u[0]
            y = u[1]
            z = u[2]
        }
        
        if x == 1 && y == 0 && z == 0 {
            return [
                [1, 0, 0],
                [0, 1 - (2 * sinA2), -2 * sinA * cosA],
                [0, 2 * sinA * cosA, 1 - (2 * sinA2)]
            ]
        } else if x == 0 && y == 1 && z == 0 {
            return [
                [1 - (2 * sinA2), 0, 2 * sinA * cosA],
                [0, 1, 0],
                [-2 * sinA * cosA, 0, 1 - (2 * sinA2)]
            ]
        } else if x == 0 && y == 0 && z == 1 {
            return [
                [1 - (2 * sinA2), -2 * sinA * cosA, 0],
                [2 * sinA * cosA, 1 - (2 * sinA2), 0],
                [0, 0, 1]
            ]
        } else {
            let x2 = x * x
            let y2 = y * y
            let z2 = z * z
            return [
                [
                    1 - (2 * (y2 + z2) * sinA2),
                    2 * ((x * y * sinA2) - (z * sinA * cosA)),
                    2 * ((x * z * sinA2) + (y * sinA * cosA))
                ],
                [
                    2 * ((y * x * sinA2) + (z * sinA * cosA)),
                    1 - (2 * (z2 + x2) * sinA2),
                    2 * ((y * z * sinA2) - (x * sinA * cosA))
                ],
                [
                    2 * ((z * x * sinA2) - (y * sinA * cosA)),
                    2 * ((z * y * sinA2) + (x * sinA * cosA)),
                    1 - (2 * (x2 + y2) * sinA2)
                ]
            ]
        }
    }
    
    internal static func vectorToVectorRotation(_ vec1: Vec3, _ vec2: Vec3) -> Matrix3 {
        let axis = Vector3.cross(vec1, vec2)
        let angle = acos(Vector3.dot(vec1, vec2))
        return rotationMatrix(angle: angle, axisX: axis[0], axisY: axis[1], axisZ: axis[2])
    }
}

