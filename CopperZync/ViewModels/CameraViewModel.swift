import SwiftUI
import AVFoundation
import Photos
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
    @Published var photoLibraryPermissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isSavingToLibrary = false
    @Published var showSaveSuccess = false
    
    let cameraService = CameraService()
    
    init() {
        setupBindings()
        checkPhotoLibraryPermission()
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
    
    func retakePhoto() {
        print("CameraViewModel: Retake photo requested")
        // Clear the captured image state first
        clearCapturedImage()
        
        // Ensure camera is stopped before restarting
        stopCamera()
        
        // Longer delay to ensure proper state transition and camera restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("CameraViewModel: Restarting camera after retake")
            self.startCamera()
        }
    }
    
    func proceedWithAnalysis() {
        // This will be called when user wants to proceed with coin identification
        // The captured image is already stored and ready for analysis
        print("Proceeding with analysis for image captured at: \(photoCaptureTime?.description ?? "unknown")")
    }
    
    func requestCameraPermission() {
        cameraService.checkCameraPermission()
    }
    
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    func dismissSaveSuccess() {
        showSaveSuccess = false
    }
    
    // MARK: - Photo Library Permission and Management
    
    func checkPhotoLibraryPermission() {
        photoLibraryPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.photoLibraryPermissionStatus = status
                if status == .authorized || status == .limited {
                    self?.savePhotoToLibrary()
                } else {
                    self?.errorMessage = Constants.Text.photoLibraryPermissionError
                    self?.showError = true
                }
            }
        }
    }
    
    func savePhotoToLibrary() {
        guard let image = capturedImage else { return }
        
        // Check permission first
        switch photoLibraryPermissionStatus {
        case .authorized, .limited:
            performSaveToLibrary(image: image)
        case .denied, .restricted:
            errorMessage = Constants.Text.photoLibraryPermissionError
            showError = true
        case .notDetermined:
            requestPhotoLibraryPermission()
        @unknown default:
            errorMessage = Constants.Text.photoLibrarySaveError
            showError = true
        }
    }
    
    private func performSaveToLibrary(image: UIImage) {
        isSavingToLibrary = true
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isSavingToLibrary = false
                
                if success {
                    self?.showSaveSuccess = true
                    print("Photo saved to library successfully")
                } else {
                    self?.errorMessage = "\(Constants.Text.photoLibrarySaveError): \(error?.localizedDescription ?? "Unknown error")"
                    self?.showError = true
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