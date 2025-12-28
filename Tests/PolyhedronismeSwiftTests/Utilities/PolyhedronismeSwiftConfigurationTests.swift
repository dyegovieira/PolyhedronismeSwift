import XCTest
@testable import PolyhedronismeSwift

final class PolyhedronismeSwiftConfigurationTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.resetToDefaults()
    }
    
    func testSharedInstance() {
        let config1 = PolyhedronismeSwiftConfiguration.shared
        let config2 = PolyhedronismeSwiftConfiguration.shared
        
        XCTAssertIdentical(config1 as AnyObject, config2 as AnyObject, "Shared should return same instance")
    }
    
    func testDefaultParallelismEnabled() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        let snapshot = await config.snapshot()
        
        XCTAssertTrue(snapshot.parallelismEnabled, "Parallelism should be enabled by default")
    }
    
    func testSetParallelismEnabled() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(false)
        
        let snapshot = await config.snapshot()
        XCTAssertFalse(snapshot.parallelismEnabled)
        
        await config.setParallelismEnabled(true)
        let snapshot2 = await config.snapshot()
        XCTAssertTrue(snapshot2.parallelismEnabled)
    }
    
    func testMaxParallelTasks() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        let defaultSnapshot = await config.snapshot()
        
        XCTAssertGreaterThan(defaultSnapshot.maxParallelTasks, 0, "Should have at least 1 task")
        
        await config.setMaxParallelTasks(4)
        let snapshot = await config.snapshot()
        XCTAssertEqual(snapshot.maxParallelTasks, 4)
    }
    
    func testMaxParallelTasksMinimumValue() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        
        await config.setMaxParallelTasks(0)
        let snapshot = await config.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.maxParallelTasks, 1, "Should enforce minimum of 1")
        
        await config.setMaxParallelTasks(-5)
        let snapshot2 = await config.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot2.maxParallelTasks, 1, "Should enforce minimum of 1")
    }
    
    func testMinParallelWorkload() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        let defaultSnapshot = await config.snapshot()
        
        XCTAssertEqual(defaultSnapshot.minParallelWorkload, 256, "Default should be 256")
        
        await config.setMinParallelWorkload(512)
        let snapshot = await config.snapshot()
        XCTAssertEqual(snapshot.minParallelWorkload, 512)
    }
    
    func testMinParallelWorkloadMinimumValue() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        
        await config.setMinParallelWorkload(0)
        let snapshot = await config.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.minParallelWorkload, 1, "Should enforce minimum of 1")
        
        await config.setMinParallelWorkload(-10)
        let snapshot2 = await config.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot2.minParallelWorkload, 1, "Should enforce minimum of 1")
    }
    
    func testSnapshotContainsAllValues() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(false)
        await config.setMaxParallelTasks(8)
        await config.setMinParallelWorkload(128)
        
        let snapshot = await config.snapshot()
        
        XCTAssertFalse(snapshot.parallelismEnabled)
        XCTAssertEqual(snapshot.maxParallelTasks, 8)
        XCTAssertEqual(snapshot.minParallelWorkload, 128)
    }
    
    func testSnapshotIsSendable() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        let snapshot = await config.snapshot()
        
        let sendableSnapshot: Sendable = snapshot
        XCTAssertNotNil(sendableSnapshot)
    }
    
    // MARK: - Property Accessor Tests
    
    func testParallelismEnabledPropertyGetter() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setParallelismEnabled(false)
        
        let value = await config.parallelismEnabled
        XCTAssertFalse(value, "Property getter should return false")
        
        await config.setParallelismEnabled(true)
        let value2 = await config.parallelismEnabled
        XCTAssertTrue(value2, "Property getter should return true")
    }
    
    func testParallelismEnabledPropertySetter() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        
        // Use the method to set, then verify via property getter
        await config.setParallelismEnabled(false)
        let value = await config.parallelismEnabled
        XCTAssertFalse(value, "Property getter should reflect set value")
        
        await config.setParallelismEnabled(true)
        let value2 = await config.parallelismEnabled
        XCTAssertTrue(value2, "Property getter should reflect set value")
    }
    
    func testMaxParallelTasksPropertyGetter() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setMaxParallelTasks(8)
        
        let value = await config.maxParallelTasks
        XCTAssertEqual(value, 8, "Property getter should return set value")
    }
    
    func testMaxParallelTasksPropertySetter() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        
        // Use the method to set, then verify via property getter
        await config.setMaxParallelTasks(4)
        let value = await config.maxParallelTasks
        XCTAssertEqual(value, 4, "Property getter should reflect set value")
        
        // Test validation in setter (via method)
        await config.setMaxParallelTasks(0)
        let value2 = await config.maxParallelTasks
        XCTAssertGreaterThanOrEqual(value2, 1, "Property setter should enforce minimum")
        
        await config.setMaxParallelTasks(-5)
        let value3 = await config.maxParallelTasks
        XCTAssertGreaterThanOrEqual(value3, 1, "Property setter should enforce minimum")
    }
    
    func testMinParallelWorkloadPropertyGetter() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        await config.setMinParallelWorkload(512)
        
        let value = await config.minParallelWorkload
        XCTAssertEqual(value, 512, "Property getter should return set value")
    }
    
    func testMinParallelWorkloadPropertySetter() async {
        let config = PolyhedronismeSwiftConfiguration.shared
        
        // Use the method to set, then verify via property getter
        await config.setMinParallelWorkload(128)
        let value = await config.minParallelWorkload
        XCTAssertEqual(value, 128, "Property getter should reflect set value")
        
        // Test validation in setter (via method)
        await config.setMinParallelWorkload(0)
        let value2 = await config.minParallelWorkload
        XCTAssertGreaterThanOrEqual(value2, 1, "Property setter should enforce minimum")
        
        await config.setMinParallelWorkload(-10)
        let value3 = await config.minParallelWorkload
        XCTAssertGreaterThanOrEqual(value3, 1, "Property setter should enforce minimum")
    }
    
    // MARK: - Property Setter Coverage Tests
    
    // Note: In Swift 6, actor properties cannot be directly assigned from outside the actor.
    // The property setters (lines 27, 32, 37) are exercised when the property is accessed
    // within the actor context. Since we can't directly test property assignment from outside,
    // we rely on the existing setter methods which have been thoroughly tested.
    // The property setters will be executed when code runs within the actor's isolation domain.
}

