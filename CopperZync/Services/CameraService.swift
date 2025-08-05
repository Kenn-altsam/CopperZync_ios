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
    
    // Camera properties - using nonisolated(unsafe) for manual concurrency management
    nonisolated(unsafe) private var captureSession: AVCaptureSession?
    nonisolated(unsafe) private var photoOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
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
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        if captureSession?.canAddOutput(photoOutput!) == true {
            captureSession?.addOutput(photoOutput!)
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
            }
        }
    }
    
    func stopCamera() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            self.captureSession?.stopRunning()
            await MainActor.run {
                self.isCameraActive = false
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
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
} 

