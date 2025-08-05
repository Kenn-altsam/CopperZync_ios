import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CameraViewModel()
    @State private var showFullScreenPhoto = false
    @State private var showCoinInfo = false
    
    var body: some View {
        ZStack {
            // Background
            Constants.Colors.lightGold
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Constants.Colors.primaryGold)
                            .background(Circle().fill(Constants.Colors.pureWhite))
                    }
                    
                    Spacer()
                    
                    Text(viewModel.showCapturedImage ? "Review Photo" : "Camera")
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
                .padding(.bottom, 20)
                
                // Main Content
                if viewModel.showCapturedImage, let capturedImage = viewModel.capturedImage {
                    // Photo Review Mode
                    VStack(spacing: 24) {
                        // Captured Photo (smaller size)
                        VStack(spacing: 12) {
                            Text("Photo Captured")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let captureTime = viewModel.photoCaptureTime {
                                Text(captureTime, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Photo Display (smaller, tappable)
                        Button(action: { showFullScreenPhoto = true }) {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                                .frame(height: UIScreen.main.bounds.height * 0.4)
                                .background(Constants.Colors.pureWhite)
                                .cornerRadius(Constants.Layout.cardCornerRadius)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .overlay(
                                    // Tap indicator
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(8)
                                                .background(Constants.Colors.lightGold)
                                                .clipShape(Circle())
                                                .padding(8)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Proceed with analysis button
                            Button(action: { showCoinInfo = true }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Identify Coin")
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
                            
                            // Retake photo button
                            Button(action: viewModel.retakePhoto) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Retake Photo")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Constants.Colors.primaryGold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Constants.Colors.pureWhite)
                                .cornerRadius(Constants.Layout.cardCornerRadius)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            
                            // Save to library button
                            Button(action: viewModel.savePhotoToLibrary) {
                                HStack {
                                    if viewModel.isSavingToLibrary {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.darkGold))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    Text(viewModel.isSavingToLibrary ? Constants.Text.savingToLibraryTitle : Constants.Text.saveToLibraryTitle)
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
                            .disabled(viewModel.isSavingToLibrary)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                } else if viewModel.isCameraActive {
                    // Camera Mode
                    ZStack {
                        // Camera preview
                        CameraPreviewView(cameraService: viewModel.cameraService)
                            .ignoresSafeArea()
                        
                        // Camera controls overlay
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 20) {
                                // Camera instructions
                                Text("Position the coin in the center")
                                    .font(.headline)
                                    .foregroundColor(Constants.Colors.pureWhite)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                // Capture button
                                Button(action: viewModel.capturePhoto) {
                                    ZStack {
                                        Circle()
                                            .fill(Constants.Colors.primaryGold)
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.pureWhite))
                                                .scaleEffect(1.2)
                                        } else {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30, weight: .medium))
                                                .foregroundColor(Constants.Colors.pureWhite)
                                        }
                                    }
                                }
                                .disabled(viewModel.isLoading)
                                
                                Text("Tap to capture")
                                    .font(.caption)
                                    .foregroundColor(Constants.Colors.pureWhite)
                                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            }
                            .padding(.bottom, 50)
                        }
                    }
                    
                } else {
                    // Camera Setup Mode
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Constants.Colors.primaryGold)
                        
                        Text("Camera Setup")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Tap the button below to start the camera")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Text("The camera will start in 10 seconds...")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: viewModel.startCamera) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Start Camera")
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
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            viewModel.requestCameraPermission()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .alert("Camera Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
        .alert(Constants.Text.photoSavedTitle, isPresented: $viewModel.showSaveSuccess) {
            Button("OK") {
                viewModel.dismissSaveSuccess()
            }
        } message: {
            Text(Constants.Text.photoSavedMessage)
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            // Full Screen Photo View
            FullScreenPhotoView(image: viewModel.capturedImage, dismiss: { showFullScreenPhoto = false })
        }
        .sheet(isPresented: $showCoinInfo) {
            CoinInfoView()
        }
    }
}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    let image: UIImage?
    let dismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if let image = image {
                // Full screen image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
}

#Preview {
    CameraView()
} 