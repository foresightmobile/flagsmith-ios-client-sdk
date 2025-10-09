
@testable import FlagsmithClient
import XCTest

final class NetworkConfigTests: FlagsmithClientTestCase {
    
    func testDefaultNetworkConfigValues() {
        let networkConfig = NetworkConfig()
        
        XCTAssertEqual(networkConfig.requestTimeout, 60.0, "Default request timeout should be 60 seconds")
        XCTAssertEqual(networkConfig.resourceTimeout, 604800.0, "Default resource timeout should be 7 days")
        XCTAssertTrue(networkConfig.waitsForConnectivity, "Default waitsForConnectivity should be true")
        XCTAssertTrue(networkConfig.allowsCellularAccess, "Default allowsCellularAccess should be true")
        XCTAssertEqual(networkConfig.httpMaximumConnectionsPerHost, 6, "Default httpMaximumConnectionsPerHost should be 6")
        XCTAssertTrue(networkConfig.httpAdditionalHeaders.isEmpty, "Default httpAdditionalHeaders should be empty")
        XCTAssertTrue(networkConfig.httpShouldUsePipelining, "Default httpShouldUsePipelining should be true")
        XCTAssertTrue(networkConfig.httpShouldSetCookies, "Default httpShouldSetCookies should be true")
    }
    
    func testNetworkConfigCustomization() {
        let networkConfig = NetworkConfig()
        
        // Test request timeout customization
        networkConfig.requestTimeout = 30.0
        XCTAssertEqual(networkConfig.requestTimeout, 30.0)
        
        // Test resource timeout customization
        networkConfig.resourceTimeout = 300.0
        XCTAssertEqual(networkConfig.resourceTimeout, 300.0)
        
        // Test connectivity settings
        networkConfig.waitsForConnectivity = false
        XCTAssertFalse(networkConfig.waitsForConnectivity)
        
        networkConfig.allowsCellularAccess = false
        XCTAssertFalse(networkConfig.allowsCellularAccess)
        
        // Test HTTP settings
        networkConfig.httpMaximumConnectionsPerHost = 10
        XCTAssertEqual(networkConfig.httpMaximumConnectionsPerHost, 10)
        
        networkConfig.httpAdditionalHeaders = ["Custom-Header": "Custom-Value"]
        XCTAssertEqual(networkConfig.httpAdditionalHeaders["Custom-Header"], "Custom-Value")
        
        networkConfig.httpShouldUsePipelining = false
        XCTAssertFalse(networkConfig.httpShouldUsePipelining)
        
        networkConfig.httpShouldSetCookies = false
        XCTAssertFalse(networkConfig.httpShouldSetCookies)
    }
    
    func testFlagsmithNetworkConfigProperty() {
        let flagsmith = Flagsmith.shared
        
        // Test default values
        XCTAssertEqual(flagsmith.networkConfig.requestTimeout, 60.0)
        XCTAssertEqual(flagsmith.networkConfig.resourceTimeout, 604800.0)
        XCTAssertTrue(flagsmith.networkConfig.waitsForConnectivity)
        XCTAssertTrue(flagsmith.networkConfig.allowsCellularAccess)
        XCTAssertEqual(flagsmith.networkConfig.httpMaximumConnectionsPerHost, 6)
        XCTAssertTrue(flagsmith.networkConfig.httpAdditionalHeaders.isEmpty)
        XCTAssertTrue(flagsmith.networkConfig.httpShouldUsePipelining)
        XCTAssertTrue(flagsmith.networkConfig.httpShouldSetCookies)
        
        // Test customization
        flagsmith.networkConfig.requestTimeout = 1.0
        XCTAssertEqual(flagsmith.networkConfig.requestTimeout, 1.0)
        
        flagsmith.networkConfig.httpAdditionalHeaders = ["Test-Header": "Test-Value"]
        XCTAssertEqual(flagsmith.networkConfig.httpAdditionalHeaders["Test-Header"], "Test-Value")
    }
    
    func testNetworkConfigThreadSafety() {
        let flagsmith = Flagsmith.shared
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        // Store initial values to restore later
        let initialTimeout = flagsmith.networkConfig.requestTimeout
        let initialHeaders = flagsmith.networkConfig.httpAdditionalHeaders
        
        // Test concurrent access to network config
        for i in 0..<10 {
            DispatchQueue.global().async {
                // Test that we can safely set values concurrently
                flagsmith.networkConfig.requestTimeout = Double(i)
                flagsmith.networkConfig.httpAdditionalHeaders = ["Thread-\(i)": "Value-\(i)"]
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify that the configuration was updated and no crashes occurred
        // The exact final value is unpredictable due to concurrent access, but it should be valid
        XCTAssertTrue(flagsmith.networkConfig.requestTimeout >= 0.0)
        XCTAssertTrue(flagsmith.networkConfig.requestTimeout <= 9.0)
        XCTAssertTrue(flagsmith.networkConfig.httpAdditionalHeaders.count >= 0)
        
        // Restore initial values to avoid affecting other tests
        flagsmith.networkConfig.requestTimeout = initialTimeout
        flagsmith.networkConfig.httpAdditionalHeaders = initialHeaders
    }
    
    func testNetworkConfigValidation() {
        let networkConfig = NetworkConfig()
        
        // Test negative timeout values (should be allowed as URLSessionConfiguration accepts them)
        networkConfig.requestTimeout = -1.0
        XCTAssertEqual(networkConfig.requestTimeout, -1.0)
        
        networkConfig.resourceTimeout = 0.0
        XCTAssertEqual(networkConfig.resourceTimeout, 0.0)
        
        // Test large timeout values
        networkConfig.requestTimeout = 3600.0 // 1 hour
        XCTAssertEqual(networkConfig.requestTimeout, 3600.0)
        
        // Test zero connections per host
        networkConfig.httpMaximumConnectionsPerHost = 0
        XCTAssertEqual(networkConfig.httpMaximumConnectionsPerHost, 0)
        
        // Test large number of connections per host
        networkConfig.httpMaximumConnectionsPerHost = 100
        XCTAssertEqual(networkConfig.httpMaximumConnectionsPerHost, 100)
    }
    
    func testNetworkConfigEquality() {
        let config1 = NetworkConfig()
        let config2 = NetworkConfig()
        
        // Identical configs should be equal
        XCTAssertEqual(config1.requestTimeout, config2.requestTimeout)
        XCTAssertEqual(config1.resourceTimeout, config2.resourceTimeout)
        XCTAssertEqual(config1.waitsForConnectivity, config2.waitsForConnectivity)
        XCTAssertEqual(config1.allowsCellularAccess, config2.allowsCellularAccess)
        XCTAssertEqual(config1.httpMaximumConnectionsPerHost, config2.httpMaximumConnectionsPerHost)
        XCTAssertEqual(config1.httpAdditionalHeaders, config2.httpAdditionalHeaders)
        XCTAssertEqual(config1.httpShouldUsePipelining, config2.httpShouldUsePipelining)
        XCTAssertEqual(config1.httpShouldSetCookies, config2.httpShouldSetCookies)
        
        // Modify one config
        config1.requestTimeout = 30.0
        XCTAssertNotEqual(config1.requestTimeout, config2.requestTimeout)
        
        // Reset and test other properties
        config1.requestTimeout = 60.0
        config1.httpAdditionalHeaders = ["Test": "Value"]
        XCTAssertNotEqual(config1.httpAdditionalHeaders, config2.httpAdditionalHeaders)
    }
}
