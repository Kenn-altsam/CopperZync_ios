import SwiftUI
import AVFoundation
import Photos
import PhotosUI
import Combine

@MainActor
class CameraViewModel: ObservableObject {
    @Published var isCameraActive = false
    @Published var capturedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showCapturedImage = false
    @Published var photoCaptureTime: Date?
    
    // Photo Picker Properties
    @Published var showPhotoPicker = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    // Coin Analysis Properties
    @Published var coinAnalysis: CoinAnalysis?
    @Published var isAnalyzing = false
    @Published var showAnalysisResult = false
    @Published var showRetryAlert = false
    
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
        
        // Log image quality metrics
        if let cgImage = image.cgImage {
            print("CameraViewModel: CGImage width: \(cgImage.width), height: \(cgImage.height)")
            print("CameraViewModel: CGImage bits per component: \(cgImage.bitsPerComponent)")
            print("CameraViewModel: CGImage bits per pixel: \(cgImage.bitsPerPixel)")
            print("CameraViewModel: CGImage bytes per row: \(cgImage.bytesPerRow)")
        }
        
        // Store the captured image and metadata
        capturedImage = image
        photoCaptureTime = Date()
        
        // Show the captured image view
        showCapturedImage = true
        
        // Stop the camera to save resources
        stopCamera()
        
        print("CameraViewModel: Photo capture flow completed - Image stored and ready for review")
    }
    
    func startCamera() {
        print("CameraViewModel: Starting camera")
        cameraService.startCamera()
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
        guard let image = capturedImage else {
            errorMessage = Constants.Text.noImageError
            showError = true
            return
        }
        
        Task {
            await analyzeCoin(image: image)
        }
    }
    
    private func analyzeCoin(image: UIImage) async {
        isAnalyzing = true
        isLoading = true
        
        do {
            let analysis = try await coinAnalysisService.analyzeCoin(image: image)
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
    
    func requestCameraPermission() {
        cameraService.checkCameraPermission()
    }
    
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    func retryAnalysis() {
        guard let image = capturedImage else { return }
        showRetryAlert = false
        Task {
            await analyzeCoin(image: image)
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