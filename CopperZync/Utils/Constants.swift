import SwiftUI

struct Constants {
    // MARK: - Colors
    struct Colors {
        static let primaryGold = Color(hex: "F5C242")
        static let darkGold = Color(hex: "F8B500")
        static let lightGold = Color(hex: "FCEABB")
        static let pureWhite = Color(hex: "FFFFFF")
        
        // Updated color scheme
        static let backgroundCream = Color(hex: "FFF4D9")
        static let cardBackground = Color(hex: "F6C65B")
        static let textColor = Color(hex: "1E1E1E")
        static let accentGold = Color(hex: "F5A623")
    }
    
    // MARK: - Text
    struct Text {
        static let appName = "CopperZync"
        static let welcomeMessage = "Welcome to"
        static let tagline = "Identify coins instantly with your camera"
        static let whatYouCanDo = "What you can do"
        
        // Feature cards
        static let instantRecognitionTitle = "Instant Recognition"
        static let instantRecognitionDescription = "Take a photo and get instant coin identification with AI-powered technology"
        
        static let detailedInformationTitle = "Detailed Information"
        static let detailedInformationDescription = "Learn about coin history, value, composition, and fascinating details"
        
        static let smartAnalysisTitle = "Smart Analysis"
        static let smartAnalysisDescription = "Advanced algorithms provide accurate coin identification and analysis"
        
        // Photo Library
        static let saveToLibraryTitle = "Save to Library"
        static let savingToLibraryTitle = "Saving..."
        static let photoSavedTitle = "Photo Saved"
        static let photoSavedMessage = "Photo has been successfully saved to your photo library!"
        static let photoLibraryPermissionError = "Photo library access is required to save photos. Please enable it in Settings."
        static let photoLibrarySaveError = "Failed to save photo to library"
        static let loadFromPhotosTitle = "Load from Photos"
        
        // Coin Analysis
        static let analyzingTitle = "Analyzing..."
        static let identifyCoinTitle = "Identify Coin"
        static let analysisErrorTitle = "Analysis Error"
        static let noImageError = "No image available for analysis"
        static let analyzingCoinTitle = "Analyzing Your Coin"
        static let aiExaminingText = "Our AI is examining the details..."
        static let mayTakeMomentText = "This may take up to 60 seconds"
        static let internetConnectionText = "The server may need time to start up. Please be patient."
        
        // Analysis Results
        static let analysisCompleteTitle = "Coin Analysis Complete"
        static let analysisCompleteSubtitle = "Here's what we found about your coin"
        static let basicInfoTitle = "Basic Information"
        static let valueAssessmentTitle = "Value Assessment"
        static let descriptionTitle = "Description"
        static let historicalContextTitle = "Historical Context"
        static let technicalDetailsTitle = "Technical Details"
        static let analyzeAnotherTitle = "Analyze Another Coin"
        static let backToCameraTitle = "Back to Camera"
        
        // Field Labels
        static let yearLabel = "First Released Year"
        static let countryLabel = "Country"
        static let denominationLabel = "Denomination"
        static let compositionLabel = "Composition"
        static let collectorValueLabel = "Collector Value"
        static let rarityLabel = "Rarity"
        static let mintMarkLabel = "Mint Mark"
        static let diameterLabel = "Diameter"
    }
    
    // MARK: - Layout
    struct Layout {
        static let cardCornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 40
        static let cardSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 24
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}