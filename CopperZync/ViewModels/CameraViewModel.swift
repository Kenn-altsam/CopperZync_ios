import SwiftUI
import AVFoundation
import Photos
import PhotosUI
import Combine

enum CoinSide {
    case front
    case back
    
    var displayName: String {
        switch self {
        case .front:
            return "Front"
        case .back:
            return "Back"
        }
    }
    
    var nextSide: CoinSide {
        switch self {
        case .front:
            return .back
        case .back:
            return .front
        }
    }
}

@MainActor
class CameraViewModel: ObservableObject {
    @Published var isCameraActive = false
    @Published var capturedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showCapturedImage = false
    @Published var photoCaptureTime: Date?
    
    // Both sides coin capture properties
    @Published var frontImage: UIImage?
    @Published var backImage: UIImage?
    @Published var currentCaptureSide: CoinSide = .front
    @Published var showBothSidesPreview = false
    
    // Photo Picker Properties
    @Published var showPhotoPicker = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    // Coin Analysis Properties
    @Published var coinAnalysis: CoinAnalysis?
    @Published var isAnalyzing = false
    @Published var showAnalysisResult = false
    @Published var showRetryAlert = false
    @Published var analysisProgress: String = "Preparing analysis..."
    
    let cameraService = CameraService()
    private let coinAnalysisService: CoinAnalysisServiceProtocol
    private let networkService: NetworkServiceProtocol
    
    init(coinAnalysisService: CoinAnalysisServiceProtocol = CoinAnalysisService(), 
         networkService: NetworkServiceProtocol = NetworkService()) {
        self.coinAnalysisService = coinAnalysisService
        self.networkService = networkService
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind camera service properties to view model
        cameraService.$isCameraActive
            .assign(to: &$isCameraActive)
        
        cameraService.$capturedImage
            .sink { [weak self] image in
                self?.handleCapturedImage(image)
            }
            .store(in: &cancellables)
        
        cameraService.$errorMessage
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.showError = errorMessage != nil
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func handleCapturedImage(_ image: UIImage?) {
        guard let image = image else { 
            print("CameraViewModel: No image received from camera service")
            return 
        }
        
        print("CameraViewModel: Image captured successfully - Size: \(image.size)")
        print("CameraViewModel: Image scale: \(image.scale)")
        print("CameraViewModel: Image orientation: \(image.imageOrientation.rawValue)")
        print("CameraViewModel: Current capture side: \(currentCaptureSide.displayName)")
        
        // Log image quality metrics
        if let cgImage = image.cgImage {
            print("CameraViewModel: CGImage width: \(cgImage.width), height: \(cgImage.height)")
            print("CameraViewModel: CGImage bits per component: \(cgImage.bitsPerComponent)")
            print("CameraViewModel: CGImage bits per pixel: \(cgImage.bitsPerPixel)")
            print("CameraViewModel: CGImage bytes per row: \(cgImage.bytesPerRow)")
        }
        
        // Store the image based on current side
        switch currentCaptureSide {
        case .front:
            frontImage = image
            currentCaptureSide = .back
            print("CameraViewModel: Front image captured, switching to back side")
            print("CameraViewModel: Front image stored, currentCaptureSide now: \(currentCaptureSide.displayName)")
        case .back:
            backImage = image
            showBothSidesPreview = true
            print("CameraViewModel: Back image captured, showing both sides preview")
            print("CameraViewModel: Back image stored, showBothSidesPreview: \(showBothSidesPreview)")
        }
        
        photoCaptureTime = Date()
        
        // Stop the camera to save resources
        stopCamera()
        
        print("CameraViewModel: Photo capture flow completed - Image stored for \(currentCaptureSide.displayName) side")
        print("CameraViewModel: Front image available: \(frontImage != nil)")
        print("CameraViewModel: Back image available: \(backImage != nil)")
    }
    
    func startCamera() {
        print("CameraViewModel: 🚀 Starting camera")
        print("CameraViewModel: Camera service isCameraAuthorized: \(cameraService.isCameraAuthorized)")
        cameraService.startCamera()
        print("CameraViewModel: Camera start command sent to camera service")
    }
    
    func stopCamera() {
        print("CameraViewModel: Stopping camera")
        cameraService.stopCamera()
    }
    
    func capturePhoto() {
        print("CameraViewModel: Capturing photo")
        isLoading = true
        cameraService.capturePhoto()
        
        // Reset loading state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    func clearCapturedImage() {
        print("CameraViewModel: Clearing captured image")
        capturedImage = nil
        photoCaptureTime = nil
        showCapturedImage = false
        cameraService.clearCapturedImage()
    }
    

    
    func proceedWithAnalysis() {
        print("CameraViewModel: Proceeding with analysis")
        print("CameraViewModel: Front image available: \(frontImage != nil)")
        print("CameraViewModel: Back image available: \(backImage != nil)")
        print("CameraViewModel: Single captured image available: \(capturedImage != nil)")
        
        // Check if we have both sides or just one side
        if let frontImage = frontImage, let backImage = backImage {
            // Both sides available
            print("CameraViewModel: Both sides available, starting analysis with both images")
            Task {
                await analyzeCoinWithBothSides(frontImage: frontImage, backImage: backImage)
            }
        } else if let singleImage = capturedImage {
            // Single image (legacy support)
            print("CameraViewModel: Single image available, starting analysis with single image")
            Task {
                await analyzeCoin(image: singleImage)
            }
        } else {
            print("CameraViewModel: No images available for analysis")
            errorMessage = "Please capture both sides of the coin for better analysis"
            showError = true
            return
        }
    }
    
    private func analyzeCoin(image: UIImage) async {
        isAnalyzing = true
        isLoading = true
        analysisProgress = "Preparing image..."
        
        do {
            await MainActor.run {
                analysisProgress = "Sending to AI for analysis..."
            }
            
            let analysis = try await coinAnalysisService.analyzeCoin(image: image)
            
            await MainActor.run {
                analysisProgress = "Processing results..."
            }
            
            coinAnalysis = analysis
            showAnalysisResult = true
            print("Coin analysis completed successfully")
        } catch {
            // Check if it's a timeout error
            if let networkError = error as? NetworkError {
                switch networkError {
                case .networkError(let underlyingError):
                    if let nsError = underlyingError as NSError? {
                        if nsError.code == NSURLErrorTimedOut {
                            errorMessage = "The server is taking longer than expected to respond. This is normal for the first request. Would you like to try again?"
                            showRetryAlert = true
                        } else {
                            errorMessage = networkError.localizedDescription
                            showError = true
                        }
                    } else {
                        errorMessage = networkError.localizedDescription
                        showError = true
                    }
                default:
                    errorMessage = networkError.localizedDescription
                    showError = true
                }
            } else {
                errorMessage = error.localizedDescription
                showError = true
            }
            print("Coin analysis failed: \(error.localizedDescription)")
        }
        
        isAnalyzing = false
        isLoading = false
    }
    
    private func analyzeCoinWithBothSides(frontImage: UIImage, backImage: UIImage) async {
        print("CameraViewModel: Starting both sides analysis")
        print("CameraViewModel: Front image size: \(frontImage.size)")
        print("CameraViewModel: Back image size: \(backImage.size)")
        
        isAnalyzing = true
        isLoading = true
        analysisProgress = "Preparing images..."
        
        do {
            await MainActor.run {
                analysisProgress = "Sending both sides to AI for analysis..."
            }
            
            print("CameraViewModel: Calling coinAnalysisService.analyzeCoinWithBothSides")
            let analysis = try await coinAnalysisService.analyzeCoinWithBothSides(frontImage: frontImage, backImage: backImage)
            
            await MainActor.run {
                analysisProgress = "Processing results..."
            }
            
            coinAnalysis = analysis
            showAnalysisResult = true
            print("Both sides coin analysis completed successfully")
        } catch {
            // Check if it's a timeout error
            if let networkError = error as? NetworkError {
                switch networkError {
                case .networkError(let underlyingError):
                    if let nsError = underlyingError as NSError? {
                        if nsError.code == NSURLErrorTimedOut {
                            errorMessage = "The server is taking longer than expected to respond. This is normal for the first request. Would you like to try again?"
                            showRetryAlert = true
                        } else {
                            errorMessage = networkError.localizedDescription
                            showError = true
                        }
                    } else {
                        errorMessage = networkError.localizedDescription
                        showError = true
                    }
                default:
                    errorMessage = networkError.localizedDescription
                    showError = true
                }
            } else {
                errorMessage = error.localizedDescription
                showError = true
            }
            print("Both sides coin analysis failed: \(error.localizedDescription)")
        }
        
        isAnalyzing = false
        isLoading = false
    }
    
    func requestCameraPermission() {
        cameraService.checkCameraPermission()
    }
    
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    func retryAnalysis() {
        showRetryAlert = false
        if let frontImage = frontImage, let backImage = backImage {
            Task {
                await analyzeCoinWithBothSides(frontImage: frontImage, backImage: backImage)
            }
        } else if let singleImage = capturedImage {
            Task {
                await analyzeCoin(image: singleImage)
            }
        }
    }
    
    func resetCaptureState() {
        frontImage = nil
        backImage = nil
        capturedImage = nil
        currentCaptureSide = .front
        showBothSidesPreview = false
        showCapturedImage = false
        photoCaptureTime = nil
        cameraService.clearCapturedImage()
    }
    
    func continueToNextSide() {
        // When we're showing the SingleSidePreviewView, currentCaptureSide is already .back
        // So we need to start the camera for the back side capture
        print("CameraViewModel: Continuing to capture back side")
        startCamera()
    }
    
    func captureBackSide() {
        print("CameraViewModel: 🎯 Capture Back Side button pressed!")
        print("CameraViewModel: Current capture side before: \(currentCaptureSide.displayName)")
        print("CameraViewModel: Front image available: \(frontImage != nil)")
        print("CameraViewModel: Camera service isCameraActive: \(cameraService.isCameraActive)")
        print("CameraViewModel: Camera service isCameraAuthorized: \(cameraService.isCameraAuthorized)")
        
        // Check camera authorization first
        if !cameraService.isCameraAuthorized {
            print("CameraViewModel: Camera not authorized, requesting permission")
            cameraService.checkCameraPermission()
            return
        }
        
        // Ensure we're in the correct state for back side capture
        currentCaptureSide = .back
        print("CameraViewModel: Current capture side after: \(currentCaptureSide.displayName)")
        
        // Stop any existing camera session first
        stopCamera()
        
        // Start the camera for back side capture
        startCamera()
        print("CameraViewModel: Camera started for back side capture")
        
        // Add a small delay to ensure camera starts properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("CameraViewModel: Camera service isCameraActive after start: \(self.cameraService.isCameraActive)")
            print("CameraViewModel: ViewModel isCameraActive: \(self.isCameraActive)")
        }
        
        // Add another check after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("CameraViewModel: Camera service isCameraActive after 1 second: \(self.cameraService.isCameraActive)")
            print("CameraViewModel: ViewModel isCameraActive after 1 second: \(self.isCameraActive)")
            
            // If camera is still not active, try to force start it
            if !self.cameraService.isCameraActive {
                print("CameraViewModel: Camera not active after 1 second, trying to force start")
                self.cameraService.startCamera()
            }
        }
    }
    
    // MARK: - Backend Connection Testing
    
    func testBackendConnection() {
        Task {
            do {
                let connectionStatus = try await networkService.testBackendConnection()
                await MainActor.run {
                    self.errorMessage = "Backend Test: \(connectionStatus)"
                    self.showError = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Backend connection failed: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    

    
    // MARK: - Photo Picker Management
    
    func selectPhotoFromLibrary() {
        showPhotoPicker = true
    }
    
    func handleSelectedPhoto(_ item: PhotosPickerItem) {
        selectedPhotoItem = item
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        // For now, use the legacy single image approach
                        // In the future, we could implement a photo picker that allows selecting multiple images
                        self.capturedImage = image
                        self.photoCaptureTime = Date()
                        self.showCapturedImage = true
                        self.stopCamera()
                        print("Photo selected from library successfully")
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to load the selected photo"
                        self.showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error loading photo: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Photo Quality and Processing
    
    func getOptimizedImage() -> UIImage? {
        guard let image = capturedImage else { return nil }
        
        // Optimize image for analysis (resize if too large, maintain quality)
        let maxDimension: CGFloat = 1024
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage
    }
} 