import Foundation
import UIKit

protocol CoinAnalysisServiceProtocol {
    func analyzeCoin(image: UIImage) async throws -> CoinAnalysis
    func analyzeCoinWithBothSides(frontImage: UIImage, backImage: UIImage) async throws -> CoinAnalysis
}

class CoinAnalysisService: CoinAnalysisServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func analyzeCoin(image: UIImage) async throws -> CoinAnalysis {
        let response = try await networkService.analyzeCoin(image: image)
        return response.coinAnalysis
    }
    
    func analyzeCoinWithBothSides(frontImage: UIImage, backImage: UIImage) async throws -> CoinAnalysis {
        print("CoinAnalysisService: Starting both sides analysis")
        print("CoinAnalysisService: Front image size: \(frontImage.size)")
        print("CoinAnalysisService: Back image size: \(backImage.size)")
        
        let response = try await networkService.analyzeCoinWithBothSides(frontImage: frontImage, backImage: backImage)
        print("CoinAnalysisService: Received response from network service")
        return response.coinAnalysis
    }
} 