import AVFoundation
import UIKit
import SwiftUI

@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var isCameraActive = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var isPreviewReady = false
    @Published var isAutoFocusing = false
    @Published var focusDistance: Float = 0.0
    
    // Camera properties - using nonisolated(unsafe) for manual concurrency management
    nonisolated(unsafe) private var captureSession: AVCaptureSession?
    nonisolated(unsafe) private var photoOutput: AVCapturePhotoOutput?
    nonisolated(unsafe) private var videoDeviceInput: AVCaptureDeviceInput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // Focus monitoring
    private var focusTimer: Timer?
    private let focusUpdateInterval: TimeInterval = 0.5
    
    // Public accessor for capture session
    var session: AVCaptureSession? {
        captureSession
    }
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
            errorMessage = "Camera access is required to identify coins. Please enable it in Settings."
        @unknown default:
            isCameraAuthorized = false
            errorMessage = "Camera access is required to identify coins."
        }
    }
    
    private func setupCamera() {
        guard isCameraAuthorized else { return }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            errorMessage = "Unable to access camera"
            return
        }
        
        // Store the device input for focus control
        videoDeviceInput = input
        
        // Configure camera for autofocus
        configureCameraForAutofocus(device: backCamera)
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        if captureSession?.canAddOutput(photoOutput!) == true {
            captureSession?.addOutput(photoOutput!)
        }
    }
    
    private func configureCameraForAutofocus(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Enable continuous autofocus
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Enable continuous auto exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            // Enable auto white balance
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Set focus point to center
            device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
            
            device.unlockForConfiguration()
        } catch {
            print("CameraService: Failed to configure camera for autofocus: \(error)")
        }
    }
    
    func startCamera() {
        guard isCameraAuthorized else {
            checkCameraPermission()
            return
        }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            self.captureSession?.startRunning()
            await MainActor.run {
                self.isCameraActive = true
                self.startFocusMonitoring()
            }
        }
    }
    
    func stopCamera() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            self.captureSession?.stopRunning()
            await MainActor.run {
                self.isCameraActive = false
                self.stopFocusMonitoring()
            }
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else {
            print("CameraService: Photo output not available")
            errorMessage = "Camera not ready"
            return
        }
        
        print("CameraService: Starting photo capture")
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func clearCapturedImage() {
        capturedImage = nil
    }
    
    // MARK: - Focus Monitoring
    
    private func startFocusMonitoring() {
        stopFocusMonitoring() // Stop any existing timer
        
        focusTimer = Timer.scheduledTimer(withTimeInterval: focusUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateFocusStatus()
        }
    }
    
    private func stopFocusMonitoring() {
        focusTimer?.invalidate()
        focusTimer = nil
        isAutoFocusing = false
    }
    
    private func updateFocusStatus() {
        guard let device = videoDeviceInput?.device else { return }
        
        // Check if device is focusing
        let isCurrentlyFocusing = device.isAdjustingFocus || device.isAdjustingExposure
        
        // Update focus distance (approximate based on lens position)
        let currentFocusDistance = device.lensPosition
        
        Task { @MainActor in
            self.isAutoFocusing = isCurrentlyFocusing
            self.focusDistance = currentFocusDistance
            
            // Trigger autofocus if object is close (lens position > 0.3 indicates closer focus)
            if currentFocusDistance > 0.3 && !isCurrentlyFocusing {
                self.triggerAutofocus()
            }
        }
    }
    
    private func triggerAutofocus() {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Set focus mode to auto focus on a single point
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
                
                // Set focus point to center of the frame
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                
                // After a brief delay, switch back to continuous autofocus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.resetToContinuousAutofocus()
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            print("CameraService: Failed to trigger autofocus: \(error)")
        }
    }
    
    private func resetToContinuousAutofocus() {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            device.unlockForConfiguration()
        } catch {
            print("CameraService: Failed to reset to continuous autofocus: \(error)")
        }
    }
    
    // MARK: - Manual Focus Control
    
    func focusAtPoint(_ point: CGPoint) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Set focus point
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
            }
            
            // Set exposure point
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
            }
            
            // Trigger autofocus
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            
            device.unlockForConfiguration()
        } catch {
            print("CameraService: Failed to focus at point: \(error)")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("CameraService: Photo capture failed with error: \(error.localizedDescription)")
            Task { @MainActor in
                self.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
            }
            return
        }
        
        print("CameraService: Photo captured successfully, processing image data")
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("CameraService: Failed to convert photo data to UIImage")
            Task { @MainActor in
                self.errorMessage = "Failed to process captured photo"
            }
            return
        }
        
        print("CameraService: Image processed successfully - Size: \(image.size)")
        
        Task { @MainActor in
            self.capturedImage = image
            print("CameraService: Image assigned to capturedImage property")
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureSession = cameraService.session else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        cameraService.videoPreviewLayer = previewLayer
        
        // Add tap gesture for focus
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraService: cameraService)
    }
    
    class Coordinator: NSObject {
        let cameraService: CameraService
        
        init(cameraService: CameraService) {
            self.cameraService = cameraService
        }
        
        @MainActor @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            
            // Convert tap location to camera coordinates
            if let previewLayer = cameraService.videoPreviewLayer {
                let cameraPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
                cameraService.focusAtPoint(cameraPoint)
            }
        }
    }
} 

