
@testable import FlagsmithClient
import XCTest

final class NetworkConfigIntegrationTests: FlagsmithClientTestCase {
    
    func testNetworkConfigValues() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration
        flagsmith.networkConfig.requestTimeout = 1.0
        flagsmith.networkConfig.resourceTimeout = 5.0
        flagsmith.networkConfig.allowsCellularAccess = false
        flagsmith.networkConfig.httpMaximumConnectionsPerHost = 2
        flagsmith.networkConfig.httpAdditionalHeaders = ["Test-Header": "Test-Value"]
        flagsmith.networkConfig.httpShouldUsePipelining = false
        flagsmith.networkConfig.httpShouldSetCookies = false
        
        // Verify the configuration is set correctly
        XCTAssertEqual(flagsmith.networkConfig.requestTimeout, 1.0)
        XCTAssertEqual(flagsmith.networkConfig.resourceTimeout, 5.0)
        XCTAssertFalse(flagsmith.networkConfig.allowsCellularAccess)
        XCTAssertEqual(flagsmith.networkConfig.httpMaximumConnectionsPerHost, 2)
        XCTAssertEqual(flagsmith.networkConfig.httpAdditionalHeaders["Test-Header"], "Test-Value")
        XCTAssertFalse(flagsmith.networkConfig.httpShouldUsePipelining)
        XCTAssertFalse(flagsmith.networkConfig.httpShouldSetCookies)
    }
    
    func testURLSessionConfigurationCreation() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration
        flagsmith.networkConfig.requestTimeout = 1.0
        flagsmith.networkConfig.resourceTimeout = 5.0
        flagsmith.networkConfig.allowsCellularAccess = false
        flagsmith.networkConfig.httpMaximumConnectionsPerHost = 2
        flagsmith.networkConfig.httpAdditionalHeaders = ["Test-Header": "Test-Value"]
        flagsmith.networkConfig.httpShouldUsePipelining = false
        flagsmith.networkConfig.httpShouldSetCookies = false
        
        // Create a URLSessionConfiguration directly
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = flagsmith.networkConfig.requestTimeout
        config.timeoutIntervalForResource = flagsmith.networkConfig.resourceTimeout
        config.waitsForConnectivity = flagsmith.networkConfig.waitsForConnectivity
        config.allowsCellularAccess = flagsmith.networkConfig.allowsCellularAccess
        config.httpMaximumConnectionsPerHost = flagsmith.networkConfig.httpMaximumConnectionsPerHost
        config.httpAdditionalHeaders = flagsmith.networkConfig.httpAdditionalHeaders
        config.httpShouldUsePipelining = flagsmith.networkConfig.httpShouldUsePipelining
        config.httpShouldSetCookies = flagsmith.networkConfig.httpShouldSetCookies
        
        // Verify the configuration is applied correctly
        XCTAssertEqual(config.timeoutIntervalForRequest, 1.0, "Request timeout should be applied")
        XCTAssertEqual(config.timeoutIntervalForResource, 5.0, "Resource timeout should be applied")
        XCTAssertFalse(config.allowsCellularAccess, "Cellular access should be disabled")
        XCTAssertEqual(config.httpMaximumConnectionsPerHost, 2, "Max connections per host should be applied")
        XCTAssertEqual(config.httpAdditionalHeaders?["Test-Header"] as? String, "Test-Value", "Additional headers should be applied")
        XCTAssertFalse(config.httpShouldUsePipelining, "HTTP pipelining should be disabled")
        XCTAssertFalse(config.httpShouldSetCookies, "HTTP cookies should be disabled")
    }
    
    func testAPIManagerUsesNetworkConfig() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration
        flagsmith.networkConfig.requestTimeout = 1.0
        flagsmith.networkConfig.resourceTimeout = 5.0
        flagsmith.networkConfig.allowsCellularAccess = false
        flagsmith.networkConfig.httpMaximumConnectionsPerHost = 2
        flagsmith.networkConfig.httpAdditionalHeaders = ["Test-Header": "Test-Value"]
        flagsmith.networkConfig.httpShouldUsePipelining = false
        flagsmith.networkConfig.httpShouldSetCookies = false
        
        // Create a new APIManager to test the configuration
        let apiManager = APIManager()
        
        // Get initial session for comparison
        let initialSession = apiManager.session
        
        // Trigger a request to apply the network configuration
        flagsmith.apiKey = TestConfig.apiKey
        let expectation = XCTestExpectation(description: "Request to apply config")
        apiManager.request(.getFlags) { result in
            // Check configuration inside the completion handler to ensure it's applied
            let sessionConfig = apiManager.session.configuration
            print("Inside completion - timeout: \(sessionConfig.timeoutIntervalForRequest)")
            print("Inside completion - headers: \(sessionConfig.httpAdditionalHeaders)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Get the session after the request
        let finalSession = apiManager.session
        
        // Debug: Print session information
        print("Initial session: \(initialSession)")
        print("Final session: \(finalSession)")
        print("Session recreated: \(initialSession !== finalSession)")
        print("Final timeout: \(finalSession.configuration.timeoutIntervalForRequest)")
        print("Final headers: \(finalSession.configuration.httpAdditionalHeaders)")
        
        // Verify that the session was recreated
        XCTAssertNotEqual(initialSession, finalSession, "Session should be recreated")
        
        // Verify that the session configuration reflects our network config
        let sessionConfig = finalSession.configuration
        XCTAssertEqual(sessionConfig.timeoutIntervalForRequest, 1.0, "Request timeout should be applied")
        XCTAssertEqual(sessionConfig.timeoutIntervalForResource, 5.0, "Resource timeout should be applied")
        XCTAssertFalse(sessionConfig.allowsCellularAccess, "Cellular access should be disabled")
        XCTAssertEqual(sessionConfig.httpMaximumConnectionsPerHost, 2, "Max connections per host should be applied")
        XCTAssertEqual(sessionConfig.httpAdditionalHeaders?["Test-Header"] as? String, "Test-Value", "Additional headers should be applied")
        XCTAssertFalse(sessionConfig.httpShouldUsePipelining, "HTTP pipelining should be disabled")
        XCTAssertFalse(sessionConfig.httpShouldSetCookies, "HTTP cookies should be disabled")
    }
    
    func testSSEManagerUsesNetworkConfig() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration
        flagsmith.networkConfig.requestTimeout = 2.0
        flagsmith.networkConfig.resourceTimeout = 10.0
        flagsmith.networkConfig.waitsForConnectivity = false
        flagsmith.networkConfig.allowsCellularAccess = false
        flagsmith.networkConfig.httpMaximumConnectionsPerHost = 1
        flagsmith.networkConfig.httpAdditionalHeaders = ["SSE-Header": "SSE-Value"]
        
        // Create a new SSEManager to test the configuration
        let sseManager = SSEManager()
        
        // Trigger the start method to apply the network configuration
        flagsmith.apiKey = TestConfig.apiKey
        let expectation = XCTestExpectation(description: "SSE start to apply config")
        sseManager.start { result in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the session configuration reflects our network config
        let sessionConfig = sseManager.session.configuration
        XCTAssertEqual(sessionConfig.timeoutIntervalForRequest, 2.0, "Request timeout should be applied")
        XCTAssertEqual(sessionConfig.timeoutIntervalForResource, 10.0, "Resource timeout should be applied")
        XCTAssertFalse(sessionConfig.waitsForConnectivity, "Wait for connectivity should be disabled")
        XCTAssertFalse(sessionConfig.allowsCellularAccess, "Cellular access should be disabled")
        XCTAssertEqual(sessionConfig.httpMaximumConnectionsPerHost, 1, "Max connections per host should be applied")
        XCTAssertEqual(sessionConfig.httpAdditionalHeaders?["SSE-Header"] as? String, "SSE-Value", "Additional headers should be applied")
        
        // Clean up
        sseManager.stop()
    }
    
    func testNetworkConfigChangesTriggerSessionRecreation() {
        let flagsmith = Flagsmith.shared
        let apiManager = APIManager()
        
        // Set initial configuration and trigger a request to create the initial session
        flagsmith.apiKey = TestConfig.apiKey
        flagsmith.networkConfig.requestTimeout = 60.0
        flagsmith.networkConfig.httpAdditionalHeaders = ["Initial": "Value"]
        
        let initialExpectation = XCTestExpectation(description: "Initial request")
        apiManager.request(.getFlags) { result in
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 1.0)
        
        // Get initial session
        let initialSession = apiManager.session
        
        // Change network configuration
        flagsmith.networkConfig.requestTimeout = 30.0
        flagsmith.networkConfig.httpAdditionalHeaders = ["Changed": "Value"]
        
        // Trigger a request to cause session recreation
        let expectation = XCTestExpectation(description: "Request completion")
        
        // Make a request that will trigger session recreation
        apiManager.request(.getFlags) { result in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify that the session was recreated with new configuration
        let newSession = apiManager.session
        XCTAssertNotEqual(initialSession, newSession, "Session should be recreated")
        XCTAssertEqual(newSession.configuration.timeoutIntervalForRequest, 30.0, "New timeout should be applied")
        XCTAssertEqual(newSession.configuration.httpAdditionalHeaders?["Changed"] as? String, "Value", "New headers should be applied")
    }
    
    func testNetworkConfigWithRealAPIKey() throws {
        // Skip this test if we don't have a real API key
        guard TestConfig.hasRealApiKey else {
            throw XCTSkip("Real API key required for integration test")
        }
        
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = TestConfig.apiKey
        flagsmith.baseURL = TestConfig.baseURL
        
        // Set a very short timeout to test timeout behavior
        flagsmith.networkConfig.requestTimeout = 0.1 // 100ms
        
        let expectation = XCTestExpectation(description: "Request with short timeout")
        
        flagsmith.getFeatureFlags { result in
            switch result {
            case .success:
                // If this succeeds, it means the request completed within 100ms
                expectation.fulfill()
            case .failure(let error):
                // We expect a timeout error with such a short timeout
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected timeout error, got: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testNetworkConfigWithCustomHeaders() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = TestConfig.apiKey
        
        // Set custom headers
        flagsmith.networkConfig.httpAdditionalHeaders = [
            "X-Custom-Header": "Custom-Value",
            "User-Agent": "FlagsmithTest/1.0"
        ]
        
        let apiManager = APIManager()
        
        // Trigger a request to apply the network configuration
        let expectation = XCTestExpectation(description: "Request to apply headers")
        apiManager.request(.getFlags) { result in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let sessionConfig = apiManager.session.configuration
        
        // Verify custom headers are applied
        XCTAssertEqual(sessionConfig.httpAdditionalHeaders?["X-Custom-Header"] as? String, "Custom-Value")
        XCTAssertEqual(sessionConfig.httpAdditionalHeaders?["User-Agent"] as? String, "FlagsmithTest/1.0")
    }
    
    func testNetworkConfigPerformance() {
        let flagsmith = Flagsmith.shared
        
        // Measure time to create and configure multiple network configs
        measure {
            for i in 0..<100 {
                flagsmith.networkConfig.requestTimeout = Double(i)
                flagsmith.networkConfig.httpAdditionalHeaders = ["Key-\(i)": "Value-\(i)"]
            }
        }
    }
}
