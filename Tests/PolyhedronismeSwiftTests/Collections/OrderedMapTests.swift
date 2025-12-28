import XCTest
@testable import PolyhedronismeSwift

final class OrderedMapTests: XCTestCase {
    func testSubscriptGetter() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        
        XCTAssertEqual(map["a"], 1)
        XCTAssertNil(map["b"])
    }
    
    func testSubscriptSetter() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        map["b"] = 2
        
        XCTAssertEqual(map["a"], 1)
        XCTAssertEqual(map["b"], 2)
    }
    
    func testKeysInserted() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        map["b"] = 2
        map["c"] = 3
        
        let keys = map.keysInserted
        XCTAssertEqual(keys, ["a", "b", "c"])
    }
    
    func testValuesInserted() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        map["b"] = 2
        map["c"] = 3
        
        let values = map.valuesInserted
        XCTAssertEqual(values, [1, 2, 3])
    }
    
    func testForEachInserted() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        map["b"] = 2
        
        var sum = 0
        map.forEachInserted { key, value in
            sum += value
        }
        
        XCTAssertEqual(sum, 3)
    }
    
    func testUpdateExistingKey() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        map["a"] = 2
        
        XCTAssertEqual(map["a"], 2)
        XCTAssertEqual(map.keysInserted.count, 1)
    }
    
    func testRemoveKey() {
        var map = OrderedMap<String, Int>()
        map["a"] = 1
        map["a"] = nil
        
        XCTAssertNil(map["a"])
        XCTAssertEqual(map.keysInserted.count, 1)
        XCTAssertEqual(map.valuesInserted.count, 0)
    }
}

