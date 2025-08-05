import SwiftUI

struct CoinInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Constants.Colors.lightGold
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Constants.Colors.primaryGold)
                            .background(Circle().fill(Constants.Colors.pureWhite))
                    }
                    
                    Spacer()
                    
                    Text("Coin Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Coming Soon Content
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "coins.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Constants.Colors.primaryGold)
                    
                    // Title
                    Text("Coming Soon!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Description
                    VStack(spacing: 16) {
                        Text("Coin Identification")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Our advanced AI-powered coin identification feature is currently in development. Soon you'll be able to:")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Feature List
                    VStack(spacing: 12) {
                        FeatureRow(icon: "magnifyingglass", text: "Identify coins from photos")
                        FeatureRow(icon: "info.circle", text: "Get detailed coin information")
                        FeatureRow(icon: "dollarsign.circle", text: "View current market values")
                        FeatureRow(icon: "book", text: "Learn coin history and facts")
                    }
                    .padding(.horizontal, 20)
                    

                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("We're working hard to bring you the best coin identification experience")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Stay tuned for updates!")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.darkGold)
                        .fontWeight(.medium)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Constants.Colors.primaryGold)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    CoinInfoView()
} 