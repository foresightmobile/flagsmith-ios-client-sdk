@testable import FlagsmithClient
import XCTest

final class NetworkConfigIntegrationTests: FlagsmithClientTestCase {
    
    func testNetworkConfigValues() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration
        flagsmith.networkConfig.requestTimeout = 1.0
        
        // Verify the configuration is applied correctly
        XCTAssertEqual(flagsmith.networkConfig.requestTimeout, 1.0, "Request timeout should be applied")
    }
    
    func testAPIManagerUsesNetworkConfig() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration BEFORE creating APIManager
        flagsmith.networkConfig.requestTimeout = 1.0
        
        // Create a new APIManager to test the configuration
        let apiManager = APIManager()
        
        // Set the API key on the APIManager instance
        apiManager.apiKey = TestConfig.apiKey
        
        // Trigger a request to apply the network configuration
        let expectation = XCTestExpectation(description: "Request to apply config")
        apiManager.request(.getFlags) { _ in
            // Check the session configuration inside the completion handler
            let sessionConfig = apiManager.session.configuration
            XCTAssertEqual(sessionConfig.timeoutIntervalForRequest, 1.0, "Request timeout should be applied")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSSEManagerUsesNetworkConfig() {
        let flagsmith = Flagsmith.shared
        
        // Set custom network configuration
        flagsmith.networkConfig.requestTimeout = 2.0
        
        // Create a new SSEManager to test the configuration
        let sseManager = SSEManager()
        
        // Set the API key on the SSEManager instance
        sseManager.apiKey = TestConfig.apiKey
        
        // Trigger the start method to apply the network configuration
        // The start method calls the completion handler immediately, so we don't need to wait
        sseManager.start { _ in
            // This will be called immediately when start() is called
        }
        
        // Verify that the session configuration reflects our network config
        let sessionConfig = sseManager.session.configuration
        XCTAssertEqual(sessionConfig.timeoutIntervalForRequest, 2.0, "Request timeout should be applied")
        
        // Clean up
        sseManager.stop()
    }
    
    func testNetworkConfigChangesTriggerSessionRecreation() {
        let flagsmith = Flagsmith.shared
        let apiManager = APIManager()
        
        // Set initial configuration and trigger a request to create the initial session
        apiManager.apiKey = TestConfig.apiKey
        flagsmith.networkConfig.requestTimeout = 60.0
        
        let initialExpectation = XCTestExpectation(description: "Initial request")
        apiManager.request(.getFlags) { _ in
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 1.0)
        
        // Verify initial configuration
        let initialSessionConfig = apiManager.session.configuration
        XCTAssertEqual(initialSessionConfig.timeoutIntervalForRequest, 60.0, "Initial timeout should be applied")
        
        // Change network configuration
        flagsmith.networkConfig.requestTimeout = 30.0
        
        // Trigger a request to apply the new configuration
        let expectation = XCTestExpectation(description: "Request completion")
        apiManager.request(.getFlags) { _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify that the new configuration is applied
        let newSessionConfig = apiManager.session.configuration
        XCTAssertEqual(newSessionConfig.timeoutIntervalForRequest, 30.0, "New timeout should be applied")
    }
    
    func testURLSessionConfigurationCreation() {
        let flagsmith = Flagsmith.shared
        flagsmith.networkConfig.requestTimeout = 1.0
        
        // Create a new APIManager to test the configuration
        let apiManager = APIManager()
        
        // Verify the configuration is applied correctly
        let config = apiManager.session.configuration
        XCTAssertEqual(config.timeoutIntervalForRequest, 1.0, "Request timeout should be applied")
    }
    
    func testNetworkConfigPerformance() {
        let flagsmith = Flagsmith.shared
        
        // Measure time to create and configure multiple network configs
        measure {
            for iteration in 0..<100 {
                flagsmith.networkConfig.requestTimeout = Double(iteration)
            }
        }
    }
}