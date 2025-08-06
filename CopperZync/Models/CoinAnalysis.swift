import Foundation

// MARK: - Main Response
struct CoinAnalysisResponse: Codable {
    let success: Bool
    let timestamp: String
    let coinAnalysis: CoinAnalysis
    let metadata: AnalysisMetadata
    
    enum CodingKeys: String, CodingKey {
        case success
        case timestamp
        case coinAnalysis = "coin_analysis"
        case metadata
    }
}

// MARK: - Coin Analysis
struct CoinAnalysis: Codable, Identifiable {
    let id = UUID()
    let basicInfo: BasicInfo
    let valueAssessment: ValueAssessment
    let description: String
    let historicalContext: String
    let technicalDetails: TechnicalDetails
    
    enum CodingKeys: String, CodingKey {
        case basicInfo = "basic_info"
        case valueAssessment = "value_assessment"
        case description
        case historicalContext = "historical_context"
        case technicalDetails = "technical_details"
    }
}

// MARK: - Basic Info
struct BasicInfo: Codable {
    let releasedYear: String
    let country: String
    let denomination: String
    let composition: String
    
    enum CodingKeys: String, CodingKey {
        case releasedYear = "released_year"
        case country
        case denomination
        case composition
    }
}

// MARK: - Value Assessment
struct ValueAssessment: Codable {
    let collectorValue: String
    let rarity: String
    
    enum CodingKeys: String, CodingKey {
        case collectorValue = "collector_value"
        case rarity
    }
}

// MARK: - Technical Details
struct TechnicalDetails: Codable {
    let mintMark: String?
    let rarity: String
    let diameterMm: String?
    
    enum CodingKeys: String, CodingKey {
        case mintMark = "mint_mark"
        case rarity
        case diameterMm = "diameter_mm"
    }
    
    // Computed property to get formatted diameter
    var formattedDiameter: String {
        guard let diameter = diameterMm, diameter.lowercased() != "unknown" else {
            return "Unknown"
        }
        
        // Try to convert to Double for formatting
        if let diameterValue = Double(diameter) {
            return String(format: "%.1f mm", diameterValue)
        }
        
        // Return as-is if it's not a number
        return "\(diameter) mm"
    }
    
    // Computed property to check if diameter is available
    var hasDiameter: Bool {
        guard let diameter = diameterMm else { return false }
        return diameter.lowercased() != "unknown" && !diameter.isEmpty
    }
}

// MARK: - Analysis Metadata
struct AnalysisMetadata: Codable {
    let modelUsed: String
    let imageFilename: String
    let imageSizeBytes: Int
    let processingTime: String
    
    enum CodingKeys: String, CodingKey {
        case modelUsed = "model_used"
        case imageFilename = "image_filename"
        case imageSizeBytes = "image_size_bytes"
        case processingTime = "processing_time"
    }
}

// MARK: - Error Response
struct AnalysisErrorResponse: Codable {
    let success: Bool
    let error: String
    let timestamp: String
} 