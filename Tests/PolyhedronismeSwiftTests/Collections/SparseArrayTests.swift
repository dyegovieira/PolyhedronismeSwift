import XCTest
@testable import PolyhedronismeSwift

final class SparseArrayTests: XCTestCase {
    func testSubscriptGetter() {
        var array = SparseArray<Int>(capacity: 10)
        array[5] = 42
        
        XCTAssertEqual(array[5], 42)
        XCTAssertNil(array[0])
    }
    
    func testSubscriptSetter() {
        var array = SparseArray<Int>(capacity: 10)
        array[3] = 10
        array[7] = 20
        
        XCTAssertEqual(array[3], 10)
        XCTAssertEqual(array[7], 20)
    }
    
    func testEnsureCapacity() {
        var array = SparseArray<Int>(capacity: 5)
        array.ensureCapacity(10)
        
        XCTAssertGreaterThanOrEqual(array.countHint, 10)
    }
    
    func testAsArray() {
        var array = SparseArray<Int>(capacity: 5)
        array[1] = 10
        array[3] = 30
        
        let result = array.asArray(size: 5)
        
        XCTAssertEqual(result.count, 5)
        XCTAssertNil(result[0])
        XCTAssertEqual(result[1], 10)
        XCTAssertNil(result[2])
        XCTAssertEqual(result[3], 30)
        XCTAssertNil(result[4])
    }
    
    func testCompacted() {
        var array = SparseArray<Int>(capacity: 5)
        array[1] = 10
        array[3] = 30
        
        let result = array.compacted(size: 5, defaultValue: 0)
        
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0], 0)
        XCTAssertEqual(result[1], 10)
        XCTAssertEqual(result[2], 0)
        XCTAssertEqual(result[3], 30)
        XCTAssertEqual(result[4], 0)
    }
    
    func testRemoveElement() {
        var array = SparseArray<Int>(capacity: 5)
        array[2] = 20
        array[2] = nil
        
        XCTAssertNil(array[2])
    }
    
    func testCountHintProperty() {
        var array = SparseArray<Int>(capacity: 10)
        XCTAssertEqual(array.countHint, 10, "countHint should match initial capacity")
        
        array.ensureCapacity(15)
        XCTAssertEqual(array.countHint, 15, "countHint should update after ensureCapacity")
        
        array.ensureCapacity(5)
        XCTAssertEqual(array.countHint, 15, "countHint should not decrease")
    }
    
    func testAsArrayWithoutSize() {
        var array = SparseArray<Int>(capacity: 5)
        array[1] = 10
        array[3] = 30
        
        let result = array.asArray()
        
        // Should use max of countHint and max key index
        XCTAssertGreaterThanOrEqual(result.count, 4)
        XCTAssertEqual(result[1], 10)
        XCTAssertEqual(result[3], 30)
    }
    
    func testCompactedWithoutSize() {
        var array = SparseArray<Int>(capacity: 5)
        array[1] = 10
        array[3] = 30
        
        let result = array.compacted(defaultValue: 0)
        
        XCTAssertGreaterThanOrEqual(result.count, 4)
        XCTAssertEqual(result[0], 0)
        XCTAssertEqual(result[1], 10)
        XCTAssertEqual(result[2], 0)
        XCTAssertEqual(result[3], 30)
    }
}

