import SwiftUI

struct BothSidesPreviewView: View {
    let frontImage: UIImage
    let backImage: UIImage
    let onRetake: () -> Void
    let onAnalyze: () -> Void
    let isAnalyzing: Bool
    let onTapImage: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Both Sides Captured")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Review your coin photos before analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Both sides display
            Button(action: onTapImage) {
                HStack(spacing: 16) {
                    // Front side
                    VStack(spacing: 8) {
                        Text("Front")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Image(uiImage: frontImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.25)
                            .background(Constants.Colors.pureWhite)
                            .cornerRadius(Constants.Layout.cardCornerRadius)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Back side
                    VStack(spacing: 8) {
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Image(uiImage: backImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.25)
                            .background(Constants.Colors.pureWhite)
                            .cornerRadius(Constants.Layout.cardCornerRadius)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Action buttons
            VStack(spacing: 16) {
                // Analyze button
                Button(action: onAnalyze) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.pureWhite))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Analyze Both Sides")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Constants.Colors.pureWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Constants.Colors.primaryGold)
                    .cornerRadius(Constants.Layout.cardCornerRadius)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .disabled(isAnalyzing)
                
                // Retake button
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                        Text("Retake Photos")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Constants.Colors.darkGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Constants.Colors.lightGold)
                    .cornerRadius(Constants.Layout.cardCornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(isAnalyzing)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview {
    BothSidesPreviewView(
        frontImage: UIImage(systemName: "photo") ?? UIImage(),
        backImage: UIImage(systemName: "photo") ?? UIImage(),
        onRetake: {},
        onAnalyze: {},
        isAnalyzing: false,
        onTapImage: {}
    )
} 