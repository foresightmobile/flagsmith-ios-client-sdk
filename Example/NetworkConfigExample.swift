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
    }
    
    private func fetchFeatureFlags(_ flagsmith: Flagsmith) {
        flagsmith.getFeatureFlags { _ in
            // Handle result...
        }
    }
    
    func demonstrateTimeoutBehavior() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Set a very short timeout to demonstrate timeout behavior
        flagsmith.networkConfig.requestTimeout = 0.1 // 100ms
        
        print("Testing with 100ms timeout...")
        
        flagsmith.getFeatureFlags { _ in
            // Handle result...
        }
    }
    
    func demonstrateCustomTimeout() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Set a custom timeout for your application's needs
        flagsmith.networkConfig.requestTimeout = 5.0 // 5 seconds
        
        print("Configured 5-second timeout for all requests")
        
        // All API requests will now use the 5-second timeout
        flagsmith.getFeatureFlags { _ in
            // Handle result...
        }
    }
    
    func demonstrateTimeoutChanges() {
        let flagsmith = Flagsmith.shared
        flagsmith.apiKey = "your-api-key-here"
        
        // Start with default timeout
        print("Using default timeout: \(flagsmith.networkConfig.requestTimeout) seconds")
        
        // Change timeout during runtime
        flagsmith.networkConfig.requestTimeout = 2.0
        print("Changed timeout to: \(flagsmith.networkConfig.requestTimeout) seconds")
        
        // All subsequent requests will use the new timeout
        flagsmith.getFeatureFlags { _ in
            // Handle result...
        }
    }
}