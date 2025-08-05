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