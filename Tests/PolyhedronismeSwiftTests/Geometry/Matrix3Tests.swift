import XCTest
@testable import PolyhedronismeSwift

final class Matrix3Tests: XCTestCase {
    func testIdentityMatrix() {
        let identity = Matrix3Operations.identity
        XCTAssertEqual(identity[0], [1.0, 0.0, 0.0])
        XCTAssertEqual(identity[1], [0.0, 1.0, 0.0])
        XCTAssertEqual(identity[2], [0.0, 0.0, 1.0])
    }
    
    func testMultiplyVector() {
        let matrix: Matrix3 = [
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
            [7.0, 8.0, 9.0]
        ]
        let vector: Vec3 = [1.0, 2.0, 3.0]
        let result = Matrix3Operations.multiplyVector(matrix, vector)
        
        XCTAssertEqual(result[0], 14.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 32.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 50.0, accuracy: 1e-10)
    }
    
    func testMultiplyVectorWithIdentity() {
        let identity = Matrix3Operations.identity
        let vector: Vec3 = [1.0, 2.0, 3.0]
        let result = Matrix3Operations.multiplyVector(identity, vector)
        XCTAssertEqual(result, vector)
    }
    
    func testMultiplyMatrices() {
        let a: Matrix3 = [
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
            [7.0, 8.0, 9.0]
        ]
        let b: Matrix3 = [
            [9.0, 8.0, 7.0],
            [6.0, 5.0, 4.0],
            [3.0, 2.0, 1.0]
        ]
        let result = Matrix3Operations.multiply(a, b)
        
        let expected: Matrix3 = [
            [30.0, 24.0, 18.0],
            [84.0, 69.0, 54.0],
            [138.0, 114.0, 90.0]
        ]
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(result[i][j], expected[i][j], accuracy: 1e-10)
            }
        }
    }
    
    func testMultiplyWithIdentity() {
        let matrix: Matrix3 = [
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
            [7.0, 8.0, 9.0]
        ]
        let identity = Matrix3Operations.identity
        
        let result1 = Matrix3Operations.multiply(matrix, identity)
        let result2 = Matrix3Operations.multiply(identity, matrix)
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(result1[i][j], matrix[i][j], accuracy: 1e-10)
                XCTAssertEqual(result2[i][j], matrix[i][j], accuracy: 1e-10)
            }
        }
    }
    
    func testRotationMatrixEulerAngles() {
        let matrix = Matrix3Operations.rotationMatrix(phi: 0.0, theta: 0.0, psi: 0.0)
        let identity = Matrix3Operations.identity
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(matrix[i][j], identity[i][j], accuracy: 1e-10)
            }
        }
    }
    
    func testRotationMatrixAxisX() {
        let matrix = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 1.0, axisY: 0.0, axisZ: 0.0)
        let vector: Vec3 = [0.0, 1.0, 0.0]
        let result = Matrix3Operations.multiplyVector(matrix, vector)
        
        XCTAssertEqual(result[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 1.0, accuracy: 1e-10)
    }
    
    func testRotationMatrixAxisY() {
        let matrix = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 0.0, axisY: 1.0, axisZ: 0.0)
        let vector: Vec3 = [1.0, 0.0, 0.0]
        let result = Matrix3Operations.multiplyVector(matrix, vector)
        
        XCTAssertEqual(result[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], -1.0, accuracy: 1e-10)
    }
    
    func testRotationMatrixAxisZ() {
        let matrix = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 0.0, axisY: 0.0, axisZ: 1.0)
        let vector: Vec3 = [1.0, 0.0, 0.0]
        let result = Matrix3Operations.multiplyVector(matrix, vector)
        
        XCTAssertEqual(result[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 1.0, accuracy: 1e-10)
        XCTAssertEqual(result[2], 0.0, accuracy: 1e-10)
    }
    
    func testRotationMatrixWithZeroAxis() {
        let matrix = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 0.0, axisY: 0.0, axisZ: 0.0)
        let identity = Matrix3Operations.identity
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(matrix[i][j], identity[i][j], accuracy: 1e-10, "Zero axis should default to Z axis")
            }
        }
    }
    
    func testRotationMatrixWithNonUnitAxis() {
        let matrix = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 2.0, axisY: 0.0, axisZ: 0.0)
        let normalized = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 1.0, axisY: 0.0, axisZ: 0.0)
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(matrix[i][j], normalized[i][j], accuracy: 1e-10, "Non-unit axis should be normalized")
            }
        }
    }
    
    func testVectorToVectorRotation() {
        let vec1: Vec3 = [1.0, 0.0, 0.0]
        let vec2: Vec3 = [0.0, 1.0, 0.0]
        let matrix = Matrix3Operations.vectorToVectorRotation(vec1, vec2)
        let result = Matrix3Operations.multiplyVector(matrix, vec1)
        
        let normalized = Vector3.normalize(result)
        let normalized2 = Vector3.normalize(vec2)
        
        XCTAssertEqual(normalized[0], normalized2[0], accuracy: 1e-6)
        XCTAssertEqual(normalized[1], normalized2[1], accuracy: 1e-6)
        XCTAssertEqual(normalized[2], normalized2[2], accuracy: 1e-6)
    }
    
    func testBackwardCompatibleWrapperFunctions() {
        let matrix: Matrix3 = [
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
            [7.0, 8.0, 9.0]
        ]
        let vector: Vec3 = [1.0, 2.0, 3.0]
        
        let result1 = Matrix3Operations.multiplyVector(matrix, vector)
        let result2 = Matrix3Operations.multiplyVector(matrix, vector)
        XCTAssertEqual(result1, result2)
        
        let a: Matrix3 = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
        let b: Matrix3 = [[2.0, 0.0, 0.0], [0.0, 2.0, 0.0], [0.0, 0.0, 2.0]]
        
        let result3 = Matrix3Operations.multiply(a, b)
        let result4 = Matrix3Operations.multiply(a, b)
        XCTAssertEqual(result3, result4)
        
        let rot1 = Matrix3Operations.rotationMatrix(phi: 0.0, theta: 0.0, psi: 0.0)
        let rot2 = Matrix3Operations.rotationMatrix(phi: 0.0, theta: 0.0, psi: 0.0)
        XCTAssertEqual(rot1, rot2)
    }
    
    func testRotationMatrixWithGeneralAxis() {
        let angle = Double.pi / 2
        let axis: Vec3 = [1.0, 1.0, 0.0]
        let normalizedAxis = Vector3.normalize(axis)
        
        let matrix = Matrix3Operations.rotationMatrix(
            angle: angle,
            axisX: normalizedAxis.x,
            axisY: normalizedAxis.y,
            axisZ: normalizedAxis.z
        )
        
        let testVector: Vec3 = [1.0, 0.0, 0.0]
        let result = Matrix3Operations.multiplyVector(matrix, testVector)
        
        XCTAssertGreaterThan(Vector3.magnitude(result), 0.9, "Result should have reasonable magnitude")
    }
    
    func testRotationMatrixWithNonUnitLengthAxis() {
        let matrix1 = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 1.0, axisY: 0.0, axisZ: 0.0)
        let matrix2 = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 2.0, axisY: 0.0, axisZ: 0.0)
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(matrix1[i][j], matrix2[i][j], accuracy: 1e-10, "Non-unit axis should be normalized")
            }
        }
    }
    
    func testVectorToVectorRotationWithParallelVectors() {
        let vec1: Vec3 = [1.0, 0.0, 0.0]
        let vec2: Vec3 = [2.0, 0.0, 0.0]
        let matrix = Matrix3Operations.vectorToVectorRotation(vec1, vec2)
        let result = Matrix3Operations.multiplyVector(matrix, vec1)
        
        let normalized = Vector3.normalize(result)
        let normalized2 = Vector3.normalize(vec2)
        
        XCTAssertEqual(normalized[0], normalized2[0], accuracy: 1e-6)
        XCTAssertEqual(normalized[1], normalized2[1], accuracy: 1e-6)
        XCTAssertEqual(normalized[2], normalized2[2], accuracy: 1e-6)
    }
    
    func testVectorToVectorRotationWithAntiparallelVectors() {
        let vec1: Vec3 = [1.0, 0.0, 0.0]
        let vec2: Vec3 = [-1.0, 0.0, 0.0]
        let matrix = Matrix3Operations.vectorToVectorRotation(vec1, vec2)
        let result = Matrix3Operations.multiplyVector(matrix, vec1)
        
        let normalized = Vector3.normalize(result)
        let normalized2 = Vector3.normalize(vec2)
        
        XCTAssertEqual(abs(normalized[0]), abs(normalized2[0]), accuracy: 1e-6)
    }
    
    func testRotationMatrixEulerAnglesNonZero() {
        let matrix = Matrix3Operations.rotationMatrix(phi: .pi / 2, theta: 0.0, psi: 0.0)
        let vector: Vec3 = [1.0, 0.0, 0.0]
        let result = Matrix3Operations.multiplyVector(matrix, vector)
        
        XCTAssertGreaterThan(Vector3.magnitude(result), 0.9, "Result should have reasonable magnitude")
    }
    
    func testEye3Constant() {
        let eye = Matrix3Operations.identity
        let identity = Matrix3Operations.identity
        
        for i in 0..<3 {
            for j in 0..<3 {
                XCTAssertEqual(eye[i][j], identity[i][j])
            }
        }
    }
    
    func testWrapperFunctionsForRotation() {
        let vec1: Vec3 = [1.0, 0.0, 0.0]
        let vec2: Vec3 = [0.0, 1.0, 0.0]
        
        let rot1 = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 0.0, axisY: 0.0, axisZ: 1.0)
        let rot2 = Matrix3Operations.rotationMatrix(angle: .pi / 2, axisX: 0.0, axisY: 0.0, axisZ: 1.0)
        XCTAssertEqual(rot1, rot2)
        
        let rot3 = Matrix3Operations.vectorToVectorRotation(vec1, vec2)
        let rot4 = Matrix3Operations.vectorToVectorRotation(vec1, vec2)
        XCTAssertEqual(rot3, rot4)
    }
}

