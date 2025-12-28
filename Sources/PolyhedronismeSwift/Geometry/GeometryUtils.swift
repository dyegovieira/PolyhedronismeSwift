//
// PolyhedronismeSwift
// GeometryUtils.swift
//
// GeometryUtils geometric operations and utilities
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Accelerate
import Foundation
import simd

internal enum GeometryUtils {
    static func log10(_ x: Double) -> Double {
        log(x) / GeometryConstants.ln10
    }
    
    internal static func significantFigures(_ n: Double, _ nsigs: Int) -> String {
        let mantissa = n / pow(10.0, floor(log10(n)))
        let truncatedMantissa = round(mantissa * pow(10.0, Double(nsigs - 1)))
        return "\(Int(truncatedMantissa))"
    }
    
    internal static func copyVecArray(_ vecArray: [Vec3]) -> [Vec3] {
        Array(vecArray)
    }
    
    internal static func tangentPoint(_ v1: Vec3, _ v2: Vec3) -> Vec3 {
        let d = v2 - v1
        let mag2 = simd_length_squared(d)
        guard mag2 > 0 else { return v1 }
        
        let crossValue = simd_cross(d, v1)
        let crossMag2 = simd_length_squared(crossValue)
        
        if crossMag2 < 1e-20 {
            return v1
        }
        
        let dotDV1 = simd_dot(d, v1)
        return v1 - ((dotDV1 / mag2) * d)
    }
    
    internal static func edgeDistance(_ v1: Vec3, _ v2: Vec3) -> Double {
        simd_length(tangentPoint(v1, v2))
    }
    
    internal static func linePointDistanceSquared(_ v1: Vec3, _ v2: Vec3, _ v3: Vec3) -> Double {
        let d21 = v2 - v1
        let d13 = v1 - v3
        let d23 = v2 - v3
        let m2 = simd_length_squared(d21)
        
        guard m2 > 0 else { return simd_length_squared(d13) }
        
        let t = -simd_dot(d13, d21) / m2
        
        if t <= 0 {
            return simd_length_squared(d13)
        } else if t >= 1 {
            return simd_length_squared(d23)
        } else {
            return simd_length_squared(simd_cross(d21, d13)) / m2
        }
    }
    
    internal static func orthogonal(_ v1: Vec3, _ v2: Vec3, _ v3: Vec3) -> Vec3 {
        simd_cross(v2 - v1, v3 - v2)
    }
    
    internal static func intersect(_ set1: [Int], _ set2: [Int], _ set3: [Int]) -> Int? {
        for s1 in set1 {
            for s2 in set2 where s1 == s2 {
                for s3 in set3 where s1 == s3 {
                    return s1
                }
            }
        }
        return nil
    }
    
    private static func sumAxis(
        _ pointer: UnsafePointer<Double>,
        stride: Int,
        count: Int
    ) -> Double {
        var result = 0.0
        vDSP_sveD(pointer, vDSP_Stride(stride), &result, vDSP_Length(count))
        return result
    }
    
    internal static func calculateCentroid(_ vertices: [Vec3]) -> Vec3 {
        guard !vertices.isEmpty else { return Vec3.zero() }
        let componentStride = MemoryLayout<Vec3>.stride / MemoryLayout<Double>.stride
        return vertices.withUnsafeBufferPointer { buffer -> Vec3 in
            guard let base = buffer.baseAddress else { return Vec3.zero() }
            return base.withMemoryRebound(
                to: Double.self,
                capacity: buffer.count * componentStride
            ) { pointer in
                let sumX = sumAxis(pointer, stride: componentStride, count: buffer.count)
                let sumY = sumAxis(pointer + 1, stride: componentStride, count: buffer.count)
                let sumZ = sumAxis(pointer + 2, stride: componentStride, count: buffer.count)
                let invCount = 1.0 / Double(buffer.count)
                return Vec3(sumX * invCount, sumY * invCount, sumZ * invCount)
            }
        }
    }
    
    internal static func calculateNormal(_ vertices: [Vec3]) -> Vec3 {
        guard vertices.count >= 3 else { return Vec3.zero() }
        var normalV = Vec3.zero()
        var v1 = vertices[vertices.count - 2]
        var v2 = vertices[vertices.count - 1]
        
        for v3 in vertices {
            normalV += orthogonal(v1, v2, v3)
            v1 = v2
            v2 = v3
        }
        return Vector3.normalize(normalV)
    }
    
    internal static func planarArea(_ vertices: [Vec3]) -> Double {
        guard vertices.count >= 3 else { return 0.0 }
        var vsum = Vec3.zero()
        var v1 = vertices[vertices.count - 2]
        var v2 = vertices[vertices.count - 1]
        
        for v3 in vertices {
            vsum += simd_cross(v1, v2)
            v1 = v2
            v2 = v3
        }
        let area = abs(simd_dot(calculateNormal(vertices), vsum) / 2.0)
        return area
    }
    
    internal static func faceSignature(_ vertices: [Vec3], _ sensitivity: Int) -> String {
        var crossArray: [Double] = []
        var v1 = vertices[vertices.count - 2]
        var v2 = vertices[vertices.count - 1]
        
        for v3 in vertices {
            let crossValue = simd_cross(v1 - v2, v3 - v2)
            crossArray.append(simd_length(crossValue))
            v1 = v2
            v2 = v3
        }
        crossArray.sort()
        
        var sig = ""
        for x in crossArray {
            sig += significantFigures(x, sensitivity)
        }
        for x in crossArray.reversed() {
            sig += significantFigures(x, sensitivity)
        }
        
        return sig
    }
    
    internal static func project2DFace(_ verts: [Vec3]) -> [[Double]] {
        let v0 = verts[0]
        let n = calculateNormal(verts)
        let c = Vector3.normalize(calculateCentroid(verts))
        let p = simd_cross(n, c)
        
        return verts.map { v in
            let vd = v - v0
            return [simd_dot(n, vd), simd_dot(p, vd)]
        }
    }
    
    internal static func perspectiveTransform(
        _ vec3: Vec3,
        maxRealDepth: Double,
        minRealDepth: Double,
        desiredRatio: Double,
        desiredLength: Double
    ) -> [Double] {
        let z0 = ((maxRealDepth * desiredRatio) - minRealDepth) / (1 - desiredRatio)
        let scaleFactor = (desiredLength * desiredRatio) / (1 - desiredRatio)
        return [
            (scaleFactor * vec3[0]) / (vec3[2] + z0),
            (scaleFactor * vec3[1]) / (vec3[2] + z0)
        ]
    }
    
    internal static func inversePerspectiveTransform(
        _ x: Double,
        _ y: Double,
        _ dx: Double,
        _ dy: Double,
        maxRealDepth: Double,
        minRealDepth: Double,
        desiredRatio: Double,
        desiredLength: Double
    ) -> Vec3 {
        let z0 = ((maxRealDepth * desiredRatio) - minRealDepth) / (1 - desiredRatio)
        let s = (desiredLength * desiredRatio) / (1 - desiredRatio)
        let xp = x - dx
        let yp = y - dy
        let s2 = s * s
        let z02 = z0 * z0
        let xp2 = xp * xp
        let yp2 = yp * yp
        
        let denominator = 2.0 * (s2 + xp2 + yp2)
        guard abs(denominator) > 1e-10 else {
            return Vec3(0.0, 0.0, 1.0)
        }
        
        let sqrtX = (4 * s2 * xp2 * z02) + (4 * xp2 * (s2 + xp2 + yp2) * (1 - z02))
        guard sqrtX >= 0 else {
            return Vec3(0.0, 0.0, 1.0)
        }
        
        let xsphere = ((2 * s * xp * z0) + sqrt(sqrtX)) / denominator
        
        let sqrtY = (4 * s2 * z02) + (4 * (s2 + xp2 + yp2) * (1 - z02))
        guard sqrtY >= 0 else {
            return Vec3(0.0, 0.0, 1.0)
        }
        
        let ysphere = (((s * yp * z0) / (s2 + xp2 + yp2)) + ((yp * sqrt(sqrtY)) / (s2 + xp2 + yp2)))
        
        let z2 = 1 - (xsphere * xsphere) - (ysphere * ysphere)
        let zsphere = z2 >= 0 ? sqrt(z2) : 0.0
        
        return Vec3(xsphere, ysphere, zsphere)
    }
    
    // Range generation utility (for base polyhedron generation)
    internal static func range(_ left: Int, _ right: Int, _ inclusive: Bool) -> [Int] {
        var range: [Int] = []
        let ascending = left < right
        let end = inclusive ? (ascending ? right + 1 : right - 1) : right
        
        if ascending {
            for i in left..<end {
                range.append(i)
            }
        } else {
            var i = left
            while i > end {
                range.append(i)
                i -= 1
            }
        }
        
        return range
    }
}

internal func tangentPoint(_ v1: Vec3, _ v2: Vec3) -> Vec3 {
    GeometryUtils.tangentPoint(v1, v2)
}

internal func edgeDist(_ v1: Vec3, _ v2: Vec3) -> Double {
    GeometryUtils.edgeDistance(v1, v2)
}

internal func linePointDist2(_ v1: Vec3, _ v2: Vec3, _ v3: Vec3) -> Double {
    GeometryUtils.linePointDistanceSquared(v1, v2, v3)
}

internal func calcCentroid(_ vertices: [Vec3]) -> Vec3 {
    GeometryUtils.calculateCentroid(vertices)
}

internal func normal(_ vertices: [Vec3]) -> Vec3 {
    GeometryUtils.calculateNormal(vertices)
}

internal func copyVecArray(_ vecArray: [Vec3]) -> [Vec3] {
    GeometryUtils.copyVecArray(vecArray)
}

// Range utility wrapper for backward compatibility
func __range__(_ left: Int, _ right: Int, _ inclusive: Bool) -> [Int] {
    GeometryUtils.range(left, right, inclusive)
}

