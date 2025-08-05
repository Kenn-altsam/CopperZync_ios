import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "FFF4D9")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Top Section with App Icon and Welcome Message
                    VStack(spacing: 16) {
                        // App Icon
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        // Welcome Message
                        VStack(spacing: 8) {
                            Text(Constants.Text.welcomeMessage)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Constants.Colors.textColor)
                            
                            Text(Constants.Text.appName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Constants.Colors.textColor)
                            
                            Text(Constants.Text.tagline)
                                .font(.body)
                                .foregroundColor(Constants.Colors.textColor.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 40)
                    
                    // What you can do section
                    VStack(alignment: .leading, spacing: 20) {
                        Text(Constants.Text.whatYouCanDo)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.Colors.textColor)
                            .padding(.horizontal, Constants.Layout.horizontalPadding)
                        
                        // Feature Cards
                        VStack(spacing: Constants.Layout.cardSpacing) {
                            ForEach(viewModel.features) { feature in
                                FeatureCardView(feature: feature)
                                    .padding(.horizontal, Constants.Layout.horizontalPadding)
                            }
                        }
                    }
                    
                        // Get Started Button
                        Button(action: viewModel.startCoinIdentification) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Get Started")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Constants.Colors.pureWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.isButtonPressed ? Constants.Colors.darkGold : Constants.Colors.primaryGold)
                            .cornerRadius(Constants.Layout.cardCornerRadius)
                            .shadow(color: Color.black.opacity(viewModel.isButtonPressed ? 0.1 : 0.2), radius: viewModel.isButtonPressed ? 2 : 4, x: 0, y: viewModel.isButtonPressed ? 1 : 2)
                            .scaleEffect(viewModel.isButtonPressed ? 0.98 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut(duration: 0.1), value: viewModel.isButtonPressed)
                        .padding(.horizontal, Constants.Layout.horizontalPadding)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCameraView) {
            CameraView()
        }

    }
}

#Preview {
    WelcomeView()
} 