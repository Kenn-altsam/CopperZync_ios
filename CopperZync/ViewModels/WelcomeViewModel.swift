import SwiftUI

@MainActor
class WelcomeViewModel: ObservableObject {
    @Published var features: [FeatureCard] = FeatureCard.sampleFeatures
    @Published var showCameraView = false
    @Published var isButtonPressed = false
    
    func startCoinIdentification() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Set button pressed state for visual feedback
        isButtonPressed = true
        
        // Immediately show camera view
        showCameraView = true
        
        // Reset button state after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isButtonPressed = false
        }
    }
} 