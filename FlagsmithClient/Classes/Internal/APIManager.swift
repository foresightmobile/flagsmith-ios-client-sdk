//
//  APIManager.swift
//  FlagsmithClient
//
//  Created by Tomash Tsiupiak on 6/20/19.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Handles interaction with a **Flagsmith** api.
final class APIManager: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private var _session: URLSession!
    internal var session: URLSession {
        get {
            propertiesSerialAccessQueue.sync { _session }
        }
        set {
            propertiesSerialAccessQueue.sync(flags: .barrier) {
                _session = newValue
            }
        }
    }

    /// Base `URL` used for requests.
    private var _baseURL = URL(string: "https://edge.api.flagsmith.com/api/v1/")!
    var baseURL: URL {
        get {
            propertiesSerialAccessQueue.sync { _baseURL }
        }
        set {
            propertiesSerialAccessQueue.sync(flags: .barrier) {
                _baseURL = newValue
            }
        }
    }

    /// Environment Key unique to an organization.
    private var _apiKey: String?
    var apiKey: String? {
        get {
            propertiesSerialAccessQueue.sync { _apiKey }
        }
        set {
            propertiesSerialAccessQueue.sync(flags: .barrier) {
                _apiKey = newValue
            }
        }
    }

    private var _lastUpdatedAt: Double?
    var lastUpdatedAt: Double? {
        get {
            propertiesSerialAccessQueue.sync { _lastUpdatedAt }
        }
        set {
            propertiesSerialAccessQueue.sync(flags: .barrier) {
                _lastUpdatedAt = newValue
            }
        }
    }

    // store the completion handlers and accumulated data for each task
    private var tasksToCompletionHandlers: [Int: @Sendable (Result<Data, any Error>) -> Void] = [:]
    private var tasksToData: [Int: Data] = [:]
    private let serialAccessQueue = DispatchQueue(label: "flagsmithSerialAccessQueue", qos: .default)
    let propertiesSerialAccessQueue = DispatchQueue(label: "propertiesSerialAccessQueue", qos: .default)

    override init() {
        super.init()
        let configuration = createURLSessionConfiguration()
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    /// Creates a URLSessionConfiguration with current network and cache settings
    private func createURLSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        
        // Apply network configuration - use default values during initialization
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 604800.0
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = 6
        configuration.httpAdditionalHeaders = [:]
        configuration.httpShouldUsePipelining = true
        configuration.httpShouldSetCookies = true
        
        // Apply cache configuration
        configuration.urlCache = URLCache.shared
        
        return configuration
    }
    
    /// Creates a URLSessionConfiguration with specific network and cache settings
    private func createURLSessionConfiguration(networkConfig: NetworkConfig, cacheConfig: CacheConfig) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        
        // Apply network configuration
        configuration.timeoutIntervalForRequest = networkConfig.requestTimeout
        configuration.timeoutIntervalForResource = networkConfig.resourceTimeout
        configuration.waitsForConnectivity = networkConfig.waitsForConnectivity
        configuration.allowsCellularAccess = networkConfig.allowsCellularAccess
        configuration.httpMaximumConnectionsPerHost = networkConfig.httpMaximumConnectionsPerHost
        configuration.httpAdditionalHeaders = networkConfig.httpAdditionalHeaders
        configuration.httpShouldUsePipelining = networkConfig.httpShouldUsePipelining
        configuration.httpShouldSetCookies = networkConfig.httpShouldSetCookies
        
        // Apply cache configuration
        configuration.urlCache = cacheConfig.cache
        
        return configuration
    }
    
    /// Helper function to compare HTTP headers dictionaries
    private func areHeadersEqual(_ headers1: [AnyHashable: Any]?, _ headers2: [AnyHashable: Any]?) -> Bool {
        guard let h1 = headers1, let h2 = headers2 else {
            return headers1 == nil && headers2 == nil
        }
        
        // Convert to [String: String] for comparison
        let dict1 = h1.compactMapValues { $0 as? String }
        let dict2 = h2.compactMapValues { $0 as? String }
        
        return dict1 == dict2
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        serialAccessQueue.sync {
            if let dataTask = task as? URLSessionDataTask {
                if let completion = tasksToCompletionHandlers[dataTask.taskIdentifier] {
                    if let error = error {
                        DispatchQueue.main.async { completion(.failure(FlagsmithError.unhandled(error))) }
                    } else {
                        let data = tasksToData[dataTask.taskIdentifier] ?? Data()
                        DispatchQueue.main.async { completion(.success(data)) }
                    }
                }
                tasksToCompletionHandlers[dataTask.taskIdentifier] = nil
                tasksToData[dataTask.taskIdentifier] = nil
            }
        }
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @Sendable @escaping (CachedURLResponse?) -> Void)
    {
        serialAccessQueue.sync {
            // intercept and modify the cache settings for the response
            if Flagsmith.shared.cacheConfig.useCache {
                let newResponse = proposedResponse.response(withExpirationDuration: Int(Flagsmith.shared.cacheConfig.cacheTTL))
                DispatchQueue.main.async { completionHandler(newResponse) }
            } else {
                // When caching is disabled, don't cache the response
                DispatchQueue.main.async { completionHandler(nil) }
            }
        }
    }

    func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        serialAccessQueue.sync {
            var existingData = tasksToData[dataTask.taskIdentifier] ?? Data()
            existingData.append(data)
            tasksToData[dataTask.taskIdentifier] = existingData
        }
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive _: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        completionHandler(.allow)
    }

    /// Base request method that handles creating a `URLRequest` and processing
    /// the `URLSession` response.
    ///
    /// - parameters:
    ///   - router: The path and parameters that should be requested.
    ///   - completion: Function block executed with the result of the request.
    private func request(_ router: Router, completion: @Sendable @escaping (Result<Data, any Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(FlagsmithError.apiKey))
            return
        }

        var request: URLRequest
        do {
            request = try router.request(baseUrl: baseURL, apiKey: apiKey)
        } catch {
            completion(.failure(error))
            return
        }

        // set the cache policy based on Flagsmith settings
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if Flagsmith.shared.cacheConfig.useCache {
            request.cachePolicy = .useProtocolCachePolicy
            if Flagsmith.shared.cacheConfig.skipAPI {
                request.cachePolicy = .returnCacheDataElseLoad
            }
        }

        // we must use the delegate form here, not the completion handler, to be able to modify the cache
        serialAccessQueue.sync {
            // Always recreate session with current network and cache configuration
            // This ensures that any changes to network config are applied immediately
            let networkConfig = Flagsmith.shared.networkConfig
            let cacheConfig = Flagsmith.shared.cacheConfig
            
            let newConfig = createURLSessionConfiguration(networkConfig: networkConfig, cacheConfig: cacheConfig)
            session = URLSession(configuration: newConfig, delegate: self, delegateQueue: OperationQueue.main)

            let task = session.dataTask(with: request)
            tasksToCompletionHandlers[task.taskIdentifier] = completion
            task.resume()
        }
    }

    /// Requests a api route and only relays success or failure of the action.
    ///
    /// - parameters:
    ///   - router: The path and parameters that should be requested.
    ///   - completion: Function block executed with the result of the request.
    func request(_ router: Router, completion: @Sendable @escaping (Result<Void, any Error>) -> Void) {
        request(router) { (result: Result<Data, Error>) in
            switch result {
            case let .failure(error):
                completion(.failure(FlagsmithError(error)))
            case .success:
                completion(.success(()))
            }
        }
    }

    /// Requests a api route and attempts the decode the response.
    ///
    /// - parameters:
    ///   - router: The path and parameters that should be requested.
    ///   - decoder: `JSONDecoder` used to deserialize the response data.
    ///   - completion: Function block executed with the result of the request.
    func request<T: Decodable>(_ router: Router, using decoder: JSONDecoder = JSONDecoder(),
                               completion: @Sendable @escaping (Result<T, any Error>) -> Void)
    {
        request(router) { (result: Result<Data, Error>) in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(data):
                do {
                    let value = try decoder.decode(T.self, from: data)
                    
                    // Ensure successful response is cached if caching is enabled
                    if Flagsmith.shared.cacheConfig.useCache {
                        self.ensureResponseIsCached(router: router, data: data)
                    }
                    
                    completion(.success(value))
                } catch {
                    completion(.failure(FlagsmithError(error)))
                }
            }
        }
    }
    
    /// Ensures that a successful response is properly cached
    /// This is a fallback mechanism in case URLSession's automatic caching fails
    private func ensureResponseIsCached(router: Router, data: Data) {
        guard let apiKey = apiKey, !apiKey.isEmpty else { return }
        
        do {
            let request = try router.request(baseUrl: baseURL, apiKey: apiKey)
            
            // Check if response is already cached
            if Flagsmith.shared.cacheConfig.cache.cachedResponse(for: request) != nil {
                return // Already cached
            }
            
            // Create a cacheable response
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": "application/json",
                    "Cache-Control": "max-age=\(Int(Flagsmith.shared.cacheConfig.cacheTTL))"
                ]
            )!
            
            let cachedResponse = CachedURLResponse(
                response: httpResponse,
                data: data,
                userInfo: nil,
                storagePolicy: .allowed
            )
            
            // Store the response in cache
            Flagsmith.shared.cacheConfig.cache.storeCachedResponse(cachedResponse, for: request)
            
        } catch {
            // If we can't create the request, just skip caching
            print("Flagsmith: Failed to manually cache response: \(error)")
        }
    }

    private func updateLastUpdatedFromRequest(_ request: URLRequest) {
        // Extract the lastUpdatedAt from the updatedAt header
        if let lastUpdatedAt = request.allHTTPHeaderFields?["x-flagsmith-document-updated-at"] {
            print("Last Updated At from header: \(lastUpdatedAt)")
            self.lastUpdatedAt = Double(lastUpdatedAt)
        }
    }
}
