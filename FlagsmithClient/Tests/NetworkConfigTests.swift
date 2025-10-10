
@testable import FlagsmithClient
import XCTest

final class NetworkConfigTests: FlagsmithClientTestCase {
    
    func testDefaultNetworkConfigValues() {
        let networkConfig = NetworkConfig()
        
        XCTAssertEqual(networkConfig.requestTimeout, 60.0, "Default request timeout should be 60 seconds")
    }
    
    func testNetworkConfigCustomization() {
        let networkConfig = NetworkConfig()
        
        // Test request timeout customization
        networkConfig.requestTimeout = 30.0
        XCTAssertEqual(networkConfig.requestTimeout, 30.0)
        
        // Test 1 second timeout as requested by customer
        networkConfig.requestTimeout = 1.0
        XCTAssertEqual(networkConfig.requestTimeout, 1.0)
    }
    
    func testFlagsmithNetworkConfigProperty() {
        let flagsmith = Flagsmith.shared
        
        // Test default values
        XCTAssertEqual(flagsmith.networkConfig.requestTimeout, 60.0)
        
        // Test customization
        flagsmith.networkConfig.requestTimeout = 1.0
        XCTAssertEqual(flagsmith.networkConfig.requestTimeout, 1.0)
    }
    
    func testNetworkConfigThreadSafety() {
        let flagsmith = Flagsmith.shared
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        // Store initial value to restore later
        let initialTimeout = flagsmith.networkConfig.requestTimeout
        
        // Test concurrent access to network config
        for i in 0..<10 {
            DispatchQueue.global().async {
                // Test that we can safely set values concurrently
                flagsmith.networkConfig.requestTimeout = Double(i)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify that the configuration was updated and no crashes occurred
        // The exact final value is unpredictable due to concurrent access, but it should be valid
        XCTAssertTrue(flagsmith.networkConfig.requestTimeout >= 0.0)
        XCTAssertTrue(flagsmith.networkConfig.requestTimeout <= 9.0)
        
        // Restore initial value to avoid affecting other tests
        flagsmith.networkConfig.requestTimeout = initialTimeout
    }
    
    func testNetworkConfigValidation() {
        let networkConfig = NetworkConfig()
        
        // Test negative timeout values (should be allowed as URLSessionConfiguration accepts them)
        networkConfig.requestTimeout = -1.0
        XCTAssertEqual(networkConfig.requestTimeout, -1.0)
        
        // Test zero timeout
        networkConfig.requestTimeout = 0.0
        XCTAssertEqual(networkConfig.requestTimeout, 0.0)
        
        // Test large timeout values
        networkConfig.requestTimeout = 3600.0 // 1 hour
        XCTAssertEqual(networkConfig.requestTimeout, 3600.0)
    }
    
    func testNetworkConfigEquality() {
        let config1 = NetworkConfig()
        let config2 = NetworkConfig()
        
        // Identical configs should be equal
        XCTAssertEqual(config1.requestTimeout, config2.requestTimeout)
        
        // Modify one config
        config1.requestTimeout = 30.0
        XCTAssertNotEqual(config1.requestTimeout, config2.requestTimeout)
        
        // Reset and test again
        config1.requestTimeout = 60.0
        XCTAssertEqual(config1.requestTimeout, config2.requestTimeout)
    }
}
