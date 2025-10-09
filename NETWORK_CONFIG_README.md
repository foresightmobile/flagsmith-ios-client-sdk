# Network Configuration

The Flagsmith iOS SDK now provides a `NetworkConfig` class that allows you to customize network communication parameters without exposing the entire `URLSessionConfiguration`. This addresses the customer requirement to reduce request timeouts and configure other network settings.

## Features

The `NetworkConfig` class exposes the following commonly used `URLSessionConfiguration` parameters:

- **Request Timeout**: `requestTimeout` - Timeout for individual requests (default: 60.0 seconds)
- **Resource Timeout**: `resourceTimeout` - Total timeout for the entire resource request (default: 604800.0 seconds / 7 days)
- **Connectivity**: `waitsForConnectivity` - Whether to wait for connectivity (default: true)
- **Cellular Access**: `allowsCellularAccess` - Whether to allow cellular access (default: true)
- **Connection Limits**: `httpMaximumConnectionsPerHost` - Max concurrent connections per host (default: 6)
- **Custom Headers**: `httpAdditionalHeaders` - Additional HTTP headers to send with requests (default: empty)
- **HTTP Pipelining**: `httpShouldUsePipelining` - Whether to use HTTP pipelining (default: true)
- **HTTP Cookies**: `httpShouldSetCookies` - Whether to automatically set cookies (default: true)

## Usage

### Basic Configuration

```swift
import FlagsmithClient

let flagsmith = Flagsmith.shared
flagsmith.apiKey = "your-api-key-here"

// Configure network settings
flagsmith.networkConfig.requestTimeout = 1.0  // 1 second timeout
flagsmith.networkConfig.resourceTimeout = 30.0  // 30 second total timeout
flagsmith.networkConfig.allowsCellularAccess = false  // WiFi only
```

### Custom Headers

```swift
// Add custom headers that will be sent with every request
flagsmith.networkConfig.httpAdditionalHeaders = [
    "X-Client-Version": "1.0.0",
    "X-Platform": "iOS",
    "X-Environment": "Production"
]
```

### Connection Limits

```swift
// Limit concurrent connections to the same host
flagsmith.networkConfig.httpMaximumConnectionsPerHost = 2
```

### Complete Example

```swift
import FlagsmithClient

class MyFlagsmithManager {
    private let flagsmith = Flagsmith.shared
    
    func setupFlagsmith() {
        // Set API key
        flagsmith.apiKey = "your-api-key-here"
        
        // Configure network settings
        configureNetworkSettings()
        
        // Configure cache settings (existing feature)
        configureCacheSettings()
    }
    
    private func configureNetworkSettings() {
        // Customer requested 1 second timeout instead of 60 seconds
        flagsmith.networkConfig.requestTimeout = 1.0
        
        // Set total resource timeout
        flagsmith.networkConfig.resourceTimeout = 30.0
        
        // Configure connectivity
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
    
    private func configureCacheSettings() {
        // Existing cache configuration
        flagsmith.cacheConfig.useCache = true
        flagsmith.cacheConfig.cacheTTL = 300.0  // 5 minutes
    }
    
    func fetchFeatureFlags() {
        flagsmith.getFeatureFlags { result in
            switch result {
            case .success(let flags):
                print("Fetched \(flags.count) feature flags")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
```

## Thread Safety

The `NetworkConfig` is thread-safe and can be modified from any thread. Changes to the configuration will automatically trigger the recreation of the underlying `URLSession` with the new settings.

## Backward Compatibility

This feature is fully backward compatible. Existing code will continue to work without any changes, using the default network configuration values.

## Implementation Details

- The `NetworkConfig` class is similar to the existing `CacheConfig` class
- Network configuration changes are applied to both `APIManager` and `SSEManager`
- The underlying `URLSession` is recreated when network settings change
- All network configuration parameters are applied consistently across all network requests

## Testing

The implementation includes comprehensive unit tests covering:
- Default configuration values
- Configuration customization
- Thread safety
- Integration with `APIManager` and `SSEManager`
- Session recreation when configuration changes

## Migration from URLSessionConfiguration

If you were previously trying to inject a custom `URLSessionConfiguration`, you can now use the `NetworkConfig` instead:

**Before (not supported):**
```swift
// This approach is not supported
let customConfig = URLSessionConfiguration.default
customConfig.timeoutIntervalForRequest = 1.0
// ... other customizations
```

**After (supported):**
```swift
// Use the new NetworkConfig
flagsmith.networkConfig.requestTimeout = 1.0
// ... other customizations
```

This approach provides better encapsulation and ensures that all network settings are applied consistently across the SDK.
