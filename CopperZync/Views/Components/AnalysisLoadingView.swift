import SwiftUI

struct AnalysisLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated coin icon
            ZStack {
                Circle()
                    .fill(Constants.Colors.lightGold)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: "medal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Constants.Colors.primaryGold)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Loading text
            VStack(spacing: 12) {
                Text(Constants.Text.analyzingCoinTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.textColor)
                
                Text(Constants.Text.aiExaminingText)
                    .font(.body)
                    .foregroundColor(Constants.Colors.textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Progress indicator
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.primaryGold))
                    .scaleEffect(1.2)
                
                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Constants.Colors.primaryGold)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }
            
            // Tips
            VStack(spacing: 8) {
                Text(Constants.Text.mayTakeMomentText)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textColor.opacity(0.6))
                
                Text(Constants.Text.internetConnectionText)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
        }
        .padding(40)
        .background(Constants.Colors.backgroundCream)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    AnalysisLoadingView()
} 