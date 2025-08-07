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
    func analyzeCoinWithBothSides(frontImage: UIImage, backImage: UIImage) async throws -> CoinAnalysisResponse
    func checkBackendHealth() async throws -> Bool
    func testBackendConnection() async throws -> String
}

class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://copperzync-backend.onrender.com"
    private let analyzeEndpoint = "/analyze"
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        // Configure URLSession for optimized performance
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0  // Reduced from 60s to 30s
        config.timeoutIntervalForResource = 45.0 // Reduced from 120s to 45s
        config.waitsForConnectivity = false      // Don't wait for connectivity
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        // Optimized network configuration for speed
        config.httpMaximumConnectionsPerHost = 2  // Increased for better throughput
        config.httpShouldUsePipelining = true     // Enable pipelining for speed
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.httpCookieStorage = nil
        
        // Disable caching to avoid stale data issues
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        
        self.session = URLSession(configuration: config)
    }
    
    func checkBackendHealth() async throws -> Bool {
        print("NetworkService: Checking backend health...")
        
        // Check network connectivity first
        guard await checkNetworkConnectivity() else {
            print("NetworkService: No internet connection available")
            throw NetworkError.noInternetConnection
        }
        
        guard let url = URL(string: baseURL + "/health") else {
            print("NetworkService: Invalid health check URL")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("NetworkService: Health check HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("NetworkService: Health check response: \(responseString)")
                    }
                    print("NetworkService: Backend is healthy and responding")
                    return true
                } else {
                    print("NetworkService: Backend returned status code: \(httpResponse.statusCode)")
                    throw NetworkError.serverError("Backend health check failed with status: \(httpResponse.statusCode)")
                }
            }
            
            throw NetworkError.serverError("Invalid response from backend")
            
        } catch {
            print("NetworkService: Health check failed: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        }
    }
    
    func testBackendConnection() async throws -> String {
        print("NetworkService: Testing backend connection...")
        
        // Test 1: Check if base URL is reachable
        guard let baseURL = URL(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("NetworkService: Base URL test - Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 404 {
                    // 404 is expected if there's no root endpoint, but server is reachable
                    return "Backend server is reachable (Status: \(httpResponse.statusCode))"
                } else {
                    return "Backend server responded with unexpected status: \(httpResponse.statusCode)"
                }
            }
            
            return "Backend server is reachable but returned invalid response"
            
        } catch {
            print("NetworkService: Base URL test failed: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        }
    }
    
    func analyzeCoin(image: UIImage) async throws -> CoinAnalysisResponse {
        guard let url = URL(string: baseURL + analyzeEndpoint) else {
            throw NetworkError.invalidURL
        }
        
        // Prepare the multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Optimized timeout for faster response
        request.timeoutInterval = 30.0 // Reduced from 60s to 30s
        
        // Create the multipart form data
        let imageData = try await prepareImageData(image)
        let body = createMultipartFormData(imageData: imageData, boundary: boundary)
        request.httpBody = body
        
        // Simplified retry logic - only 1 retry attempt
        let maxRetries = 1
        var lastError: Error?
        
        // Add timeout for the entire operation
        let operationTimeout = Task {
            try await Task.sleep(nanoseconds: 35_000_000_000) // 35 seconds total timeout
            throw NetworkError.timeout
        }
        
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
                    
                    // Debug: Log successful decoding
                    print("NetworkService: Successfully decoded response")
                    print("NetworkService: Basic Info - Year: \(analysisResponse.coinAnalysis.basicInfo.releasedYear), Country: \(analysisResponse.coinAnalysis.basicInfo.country)")
                    print("NetworkService: Technical Details - Mint Mark: \(analysisResponse.coinAnalysis.technicalDetails.mintMark ?? "None"), Composition: \(analysisResponse.coinAnalysis.technicalDetails.composition ?? "None")")
                    print("NetworkService: Metadata - Model: \(analysisResponse.metadata.modelUsed), Image Size: \(analysisResponse.metadata.imageSizeBytes)")
                    
                    // Check if the response contains all unknown values (indicates backend issue)
                    if analysisResponse.coinAnalysis.isUnknownAnalysis {
                        print("NetworkService: Backend returned all unknown values - this indicates a backend processing issue")
                        throw NetworkError.serverError("Backend is not processing images properly. Please try again later.")
                    }
                    
                    print("NetworkService: Analysis completed successfully on attempt \(attempt + 1)")
                    return analysisResponse
                } catch {
                    // Try to decode as error response
                    if let errorResponse = try? decoder.decode(AnalysisErrorResponse.self, from: data) {
                        print("NetworkService: Server returned error: \(errorResponse.error)")
                        throw NetworkError.serverError(errorResponse.error)
                    }
                    
                    // Enhanced decoding error handling
                    if let decodingError = error as? DecodingError {
                        print("NetworkService: Decoding error: \(decodingError)")
                        
                        // Try to print the raw JSON for debugging
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("NetworkService: Raw JSON response: \(responseString)")
                        }
                        
                        // Provide more specific error messages
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("NetworkService: Missing key '\(key)' at path: \(context.codingPath)")
                            throw NetworkError.serverError("Invalid response format: missing field '\(key.stringValue)'")
                        case .typeMismatch(let type, let context):
                            print("NetworkService: Type mismatch for type '\(type)' at path: \(context.codingPath)")
                            throw NetworkError.serverError("Invalid response format: type mismatch for field '\(context.codingPath.last?.stringValue ?? "unknown")'")
                        case .valueNotFound(let type, let context):
                            print("NetworkService: Value not found for type '\(type)' at path: \(context.codingPath)")
                            throw NetworkError.serverError("Invalid response format: missing value for field '\(context.codingPath.last?.stringValue ?? "unknown")'")
                        case .dataCorrupted(let context):
                            print("NetworkService: Data corrupted at path: \(context.codingPath)")
                            throw NetworkError.serverError("Invalid response format: corrupted data")
                        @unknown default:
                            print("NetworkService: Unknown decoding error")
                            throw NetworkError.serverError("Invalid response format")
                        }
                    }
                    
                    // If it's not a valid error response either, throw the original error
                    throw error
                }
                
            } catch let error as NetworkError {
                lastError = error
                print("NetworkService: NetworkError on attempt \(attempt + 1): \(error.localizedDescription)")
                if attempt < maxRetries {
                    print("NetworkService: Retrying immediately...")
                    // No delay for faster retry
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
                            print("NetworkService: Retrying connection immediately...")
                            continue
                        }
                        throw NetworkError.connectionFailed
                    case NSURLErrorNotConnectedToInternet:
                        print("NetworkService: No internet connection")
                        throw NetworkError.noInternetConnection
                    case NSURLErrorTimedOut:
                        print("NetworkService: Request timed out")
                        if attempt < maxRetries {
                            print("NetworkService: Retrying after timeout immediately...")
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
                                print("NetworkService: Retrying after checksum error immediately...")
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
                    print("NetworkService: Retrying immediately...")
                    // No delay for faster retry
                    continue
                }
                throw NetworkError.networkError(error)
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? NetworkError.networkError(NSError(domain: "Unknown", code: -1))
    }
    
    func analyzeCoinWithBothSides(frontImage: UIImage, backImage: UIImage) async throws -> CoinAnalysisResponse {
        guard let url = URL(string: baseURL + analyzeEndpoint) else {
            throw NetworkError.invalidURL
        }
        
        // Prepare the multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Optimized timeout for faster response
        request.timeoutInterval = 30.0 // Reduced from 60s to 30s
        
        // Create the multipart form data with both images
        let frontImageData = try await prepareImageData(frontImage)
        let backImageData = try await prepareImageData(backImage)
        let body = createMultipartFormDataWithBothSides(frontImageData: frontImageData, backImageData: backImageData, boundary: boundary)
        request.httpBody = body
        
        // Simplified retry logic - only 1 retry attempt
        let maxRetries = 1
        var lastError: Error?
        
        // Add timeout for the entire operation
        let operationTimeout = Task {
            try await Task.sleep(nanoseconds: 35_000_000_000) // 35 seconds total timeout
            throw NetworkError.timeout
        }
        
        for attempt in 0...maxRetries {
            print("NetworkService: Attempt \(attempt + 1) of \(maxRetries + 1) for both sides analysis")
            
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
                    
                    // Check if the response contains all unknown values (indicates backend issue)
                    if analysisResponse.coinAnalysis.isUnknownAnalysis {
                        print("NetworkService: Backend returned all unknown values - this indicates a backend processing issue")
                        throw NetworkError.serverError("Backend is not processing images properly. Please try again later.")
                    }
                    
                    print("NetworkService: Both sides analysis completed successfully on attempt \(attempt + 1)")
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
        // Optimize image for upload with faster processing
        let optimizedImage = optimizeImageForUpload(image)
        
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.7) else {
            throw NetworkError.invalidImageData
        }
        
        // Log image details for debugging
        print("NetworkService: Original image size: \(image.size)")
        print("NetworkService: Optimized image size: \(optimizedImage.size)")
        print("NetworkService: Image data size: \(imageData.count) bytes")
        print("NetworkService: Image compression quality: 0.7 (optimized for speed)")
        
        return imageData
    }
    
    private func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 800  // Reduced from 1024 for faster processing
        let size = image.size
        
        // If image is already small enough, return as is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Create new image with optimized size and faster rendering
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.5) // Reduced scale factor for speed
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
    
    private func createMultipartFormDataWithBothSides(frontImageData: Data, backImageData: Data, boundary: String) -> Data {
        var body = Data()
        
        // Add front image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"front_image\"; filename=\"coin_front.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(frontImageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add back image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"back_image\"; filename=\"coin_back.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(backImageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func checkNetworkConnectivity() async -> Bool {
        return await withTaskGroup(of: Bool.self) { group in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor")
            
            // Add network check task
            group.addTask {
                await withCheckedContinuation { continuation in
                    let pathUpdateHandler: @Sendable (NWPath) -> Void = { path in
                        let isConnected = path.status == .satisfied
                        monitor.cancel()
                        continuation.resume(returning: isConnected)
                    }
                    
                    monitor.pathUpdateHandler = pathUpdateHandler
                    monitor.start(queue: queue)
                }
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                monitor.cancel()
                return false
            }
            
            // Return the first result (either network status or timeout)
            for await result in group {
                group.cancelAll()
                return result
            }
            
            return false
        }
    }
} 
