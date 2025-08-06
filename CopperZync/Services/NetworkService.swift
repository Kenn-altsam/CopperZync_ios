import Foundation
import UIKit
import Network

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    case invalidImageData
    case timeout
    case noInternetConnection
    case connectionFailed
    case checksumError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Failed to process server response"
        case .serverError(let message):
            return message
        case .networkError(let error):
            // Check for specific network errors
            if let nsError = error as NSError? {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    return "Request timed out. The server may be starting up. Please try again."
                case NSURLErrorCannotConnectToHost:
                    return "Cannot connect to server. Please check your internet connection."
                case NSURLErrorNetworkConnectionLost:
                    return "Network connection was lost. Please try again."
                case NSURLErrorNotConnectedToInternet:
                    return "No internet connection available. Please check your network settings."
                default:
                    return "Network error: \(error.localizedDescription)"
                }
            }
            return error.localizedDescription
        case .invalidImageData:
            return "Invalid image data"
        case .timeout:
            return "Request timed out. The server may be starting up. Please try again."
        case .noInternetConnection:
            return "No internet connection available. Please check your network settings."
        case .connectionFailed:
            return "Failed to establish connection to server. Please try again."
        case .checksumError:
            return "Network data corruption detected. Please try again."
        }
    }
}

protocol NetworkServiceProtocol {
    func analyzeCoin(image: UIImage) async throws -> CoinAnalysisResponse
}

class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://copperzync-backend.onrender.com"
    private let analyzeEndpoint = "/analyze"
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        // Configure URLSession for better network handling
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 120.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        // Additional network configuration for better reliability
        config.httpMaximumConnectionsPerHost = 1
        config.httpShouldUsePipelining = false
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.httpCookieStorage = nil
        
        // Disable caching to avoid stale data issues
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        
        self.session = URLSession(configuration: config)
    }
    
    func analyzeCoin(image: UIImage) async throws -> CoinAnalysisResponse {
        // Check network connectivity first
        guard await checkNetworkConnectivity() else {
            throw NetworkError.noInternetConnection
        }
        
        guard let url = URL(string: baseURL + analyzeEndpoint) else {
            throw NetworkError.invalidURL
        }
        
        // Prepare the multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Set longer timeout for Render's cold start
        request.timeoutInterval = 60.0 // 60 seconds timeout
        
        // Create the multipart form data
        let imageData = try await prepareImageData(image)
        let body = createMultipartFormData(imageData: imageData, boundary: boundary)
        request.httpBody = body
        
        // Retry logic for Render's cold start
        let maxRetries = 2
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            print("NetworkService: Attempt \(attempt + 1) of \(maxRetries + 1)")
            
            do {
                let (data, response) = try await session.data(for: request)
                
                // Check for HTTP errors
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        // Try to parse error response
                        if let errorResponse = try? JSONDecoder().decode(AnalysisErrorResponse.self, from: data) {
                            throw NetworkError.serverError(errorResponse.error)
                        } else {
                            throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
                        }
                    }
                }
                
                // Debug: Print response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("NetworkService: HTTP Status: \(httpResponse.statusCode)")
                    print("NetworkService: Response Headers: \(httpResponse.allHeaderFields)")
                }
                print("NetworkService: Response Data Size: \(data.count) bytes")
                
                // Try to print the first 500 characters of the response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    let preview = String(responseString.prefix(500))
                    print("NetworkService: Response Preview: \(preview)")
                }
                
                // Decode the response
                let decoder = JSONDecoder()
                do {
                    let analysisResponse = try decoder.decode(CoinAnalysisResponse.self, from: data)
                    print("NetworkService: Analysis completed successfully on attempt \(attempt + 1)")
                    return analysisResponse
                } catch {
                    // Try to decode as error response
                    if let errorResponse = try? decoder.decode(AnalysisErrorResponse.self, from: data) {
                        print("NetworkService: Server returned error: \(errorResponse.error)")
                        throw NetworkError.serverError(errorResponse.error)
                    }
                    
                    // If it's not a valid error response either, throw the original error
                    throw error
                }
                
            } catch let error as NetworkError {
                lastError = error
                print("NetworkService: NetworkError on attempt \(attempt + 1): \(error.localizedDescription)")
                if attempt < maxRetries {
                    print("NetworkService: Retrying in \(pow(2.0, Double(attempt))) seconds...")
                    // Wait before retrying (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000) // 1s, 2s
                    continue
                }
                throw error
            } catch {
                lastError = error
                print("NetworkService: Error on attempt \(attempt + 1): \(error.localizedDescription)")
                
                // Check for specific network errors
                if let nsError = error as NSError? {
                    print("NetworkService: NSError code: \(nsError.code), domain: \(nsError.domain)")
                    
                    // Handle specific network errors
                    switch nsError.code {
                    case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
                        print("NetworkService: Connection error detected")
                        if attempt < maxRetries {
                            print("NetworkService: Retrying connection in \(pow(2.0, Double(attempt))) seconds...")
                            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                            continue
                        }
                        throw NetworkError.connectionFailed
                    case NSURLErrorNotConnectedToInternet:
                        print("NetworkService: No internet connection")
                        throw NetworkError.noInternetConnection
                    case NSURLErrorTimedOut:
                        print("NetworkService: Request timed out")
                        if attempt < maxRetries {
                            print("NetworkService: Retrying after timeout in \(pow(2.0, Double(attempt))) seconds...")
                            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                            continue
                        }
                        throw NetworkError.timeout
                    default:
                        // Check if it's a checksum or data corruption error
                        if nsError.localizedDescription.contains("checksum") || 
                           nsError.localizedDescription.contains("UDP") ||
                           nsError.localizedDescription.contains("offload") {
                            print("NetworkService: Checksum error detected")
                            if attempt < maxRetries {
                                print("NetworkService: Retrying after checksum error in \(pow(2.0, Double(attempt))) seconds...")
                                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                                continue
                            }
                            throw NetworkError.checksumError
                        }
                    }
                }
                
                // Debug: Print the actual response data if it's a decoding error
                if let decodingError = error as? DecodingError {
                    print("NetworkService: Decoding error details: \(decodingError)")
                }
                
                if attempt < maxRetries {
                    print("NetworkService: Retrying in \(pow(2.0, Double(attempt))) seconds...")
                    // Wait before retrying (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000) // 1s, 2s
                    continue
                }
                throw NetworkError.networkError(error)
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? NetworkError.networkError(NSError(domain: "Unknown", code: -1))
    }
    
    private func prepareImageData(_ image: UIImage) async throws -> Data {
        // Optimize image for upload
        let optimizedImage = optimizeImageForUpload(image)
        
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidImageData
        }
        
        return imageData
    }
    
    private func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let size = image.size
        
        // If image is already small enough, return as is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Create new image with optimized size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage ?? image
    }
    
    private func createMultipartFormData(imageData: Data, boundary: String) -> Data {
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"coin_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func checkNetworkConnectivity() async -> Bool {
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor")
            let semaphore = DispatchSemaphore(value: 1)
            var hasResumed = false
            
            let pathUpdateHandler: @Sendable (NWPath) -> Void = { path in
                let isConnected = path.status == .satisfied
                monitor.cancel()
                
                semaphore.wait()
                if !hasResumed {
                    hasResumed = true
                    semaphore.signal()
                    continuation.resume(returning: isConnected)
                } else {
                    semaphore.signal()
                }
            }
            
            monitor.pathUpdateHandler = pathUpdateHandler
            monitor.start(queue: queue)
            
            // Timeout after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                monitor.cancel()
                
                semaphore.wait()
                if !hasResumed {
                    hasResumed = true
                    semaphore.signal()
                    continuation.resume(returning: false)
                } else {
                    semaphore.signal()
                }
            }
        }
    }
} 
