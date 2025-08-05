import SwiftUI

struct FeatureCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    static let sampleFeatures: [FeatureCard] = [
        FeatureCard(
            icon: "camera.fill",
            title: Constants.Text.instantRecognitionTitle,
            description: Constants.Text.instantRecognitionDescription,
            iconColor: Constants.Colors.accentGold
        ),
        FeatureCard(
            icon: "info.circle.fill",
            title: Constants.Text.detailedInformationTitle,
            description: Constants.Text.detailedInformationDescription,
            iconColor: Constants.Colors.accentGold
        ),
        FeatureCard(
            icon: "brain.head.profile",
            title: Constants.Text.smartAnalysisTitle,
            description: Constants.Text.smartAnalysisDescription,
            iconColor: Constants.Colors.accentGold
        )
    ]
} 