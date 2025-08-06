import Foundation
import UIKit

protocol CoinAnalysisServiceProtocol {
    func analyzeCoin(image: UIImage) async throws -> CoinAnalysis
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
} 