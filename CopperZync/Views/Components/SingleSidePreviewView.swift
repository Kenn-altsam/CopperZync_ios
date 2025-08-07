import SwiftUI

struct SingleSidePreviewView: View {
    let capturedImage: UIImage
    let currentSide: CoinSide
    let onContinue: () -> Void
    let onRetake: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("\(currentSide.displayName) Side Captured")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Now capture the \(currentSide.nextSide.displayName.lowercased()) side")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Captured image display
            VStack(spacing: 12) {
                Text("\(currentSide.displayName) Side")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6)
                    .frame(height: UIScreen.main.bounds.height * 0.3)
                    .background(Constants.Colors.pureWhite)
                    .cornerRadius(Constants.Layout.cardCornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                // Continue to next side button
                Button(action: {
                    print("SingleSidePreviewView: 🎯 Button pressed!")
                    onContinue()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Capture \(currentSide.nextSide.displayName) Side")
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
                
                // Retake button
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                        Text("Retake \(currentSide.displayName) Side")
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
                

            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview {
    SingleSidePreviewView(
        capturedImage: UIImage(systemName: "photo") ?? UIImage(),
        currentSide: .front,
        onContinue: {},
        onRetake: {}
    )
} 