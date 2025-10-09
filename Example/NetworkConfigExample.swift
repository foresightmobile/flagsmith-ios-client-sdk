
import Foundation
import FlagsmithClient

class NetworkConfigExample {
    
    func demonstrateNetworkConfiguration() {
        // Get the shared Flagsmith instance
        let flagsmith = Flagsmith.shared
        
        // Set your API key
        flagsmith.apiKey = "your-api-key-here"
        
        // Configure network settings
        configureNetworkSettings(flagsmith)
        
        // Now all network requests will use these settings
        fetchFeatureFlags(flagsmith)
    }
    
    private func configureNetworkSettings(_ flagsmith: Flagsmith) {
        // Set a custom request timeout (customer requested 1 second instead of 60)
        flagsmith.networkConfig.requestTimeout = 1.0
        
        // Set resource timeout (total time for the entire request)
        flagsmith.networkConfig.resourceTimeout = 30.0
        
        // Configure connectivity settings
        flagsmith.networkConfig.waitsForConnectivity = true
        flagsmith.networkConfig.allowsCellularAccess = true
        
        // Configure HTTP settings
        flagsmith.networkConfig.httpMaximumConnectionsPerHost = 4
        flagsmith.networkConfig.httpShouldUsePipelining = true
        flagsmith.networkConfig.httpShouldSetCookies = true
        
        // Add custom headers
        flagsmith.networkConfig.httpAdditionalHeaders = [
            "X-Custom-Header": "Custom-Value",
            "User-Agent": "MyApp/1.0"
        ]
    }
    
    private func fetchFeatureFlags(_ flagsmith: Flagsmith) {
        flagsmith.getFeatureFlags { result in
            switch result {
            case .success(let flags):
                print("Successfully fetched \(flags.count) feature flags")
                for flag in flags {
                    print("Flag: \(flag.feature.name) - Enabled: \(flag.enabled)")
                }
            case .failure(let error):
                print("Failed to fetch feature flags: \(error)")
            }
        }
    }
    
    func demonstrateTimeoutBehavior() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Set a very short timeout to demonstrate timeout behavior
        flagsmith.networkConfig.requestTimeout = 0.1 // 100ms
        
        print("Testing with 100ms timeout...")
        
        flagsmith.getFeatureFlags { result in
            switch result {
            case .success(let flags):
                print("Unexpected success with short timeout: \(flags.count) flags")
            case .failure(let error):
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    print("Expected timeout error occurred")
                } else {
                    print("Unexpected error: \(error)")
                }
            }
        }
    }
    
    func demonstrateCustomHeaders() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Add custom headers that will be sent with every request
        flagsmith.networkConfig.httpAdditionalHeaders = [
            "X-Client-Version": "1.0.0",
            "X-Platform": "iOS",
            "X-Environment": "Production"
        ]
        
        print("Configured custom headers for all requests")
        
        // These headers will now be included in all API requests
        flagsmith.getFeatureFlags { result in
            // Handle result...
        }
    }
    
    func demonstrateCellularAccessControl() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Disable cellular access (WiFi only)
        flagsmith.networkConfig.allowsCellularAccess = false
        
        print("Configured to use WiFi only (no cellular)")
        
        // This will only work on WiFi connections
        flagsmith.getFeatureFlags { result in
            // Handle result...
        }
    }
    
    func demonstrateConnectionLimits() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Limit concurrent connections to the same host
        flagsmith.networkConfig.httpMaximumConnectionsPerHost = 2
        
        print("Limited to 2 concurrent connections per host")
        
        // This helps control resource usage
        flagsmith.getFeatureFlags { result in
            // Handle result...
        }
    }
}
