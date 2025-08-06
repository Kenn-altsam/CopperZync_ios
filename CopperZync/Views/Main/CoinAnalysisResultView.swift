import SwiftUI

struct CoinAnalysisResultView: View {
    let coinAnalysis: CoinAnalysis
    let onBack: () -> Void
    let onNewAnalysis: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Basic Info Card
                basicInfoCard
                
                // Value Assessment Card
                valueAssessmentCard
                
                // Description Card
                descriptionCard
                
                // Historical Context Card
                historicalContextCard
                
                // Technical Details Card
                technicalDetailsCard
                
                // Action Buttons
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Constants.Colors.backgroundCream)
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "medal.fill")
                .font(.system(size: 48))
                .foregroundColor(Constants.Colors.primaryGold)
            
            Text(Constants.Text.analysisCompleteTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textColor)
            
            Text(Constants.Text.analysisCompleteSubtitle)
                .font(.body)
                .foregroundColor(Constants.Colors.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: Constants.Text.basicInfoTitle, icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                infoRow(label: Constants.Text.yearLabel, value: coinAnalysis.basicInfo.releasedYear)
                infoRow(label: Constants.Text.countryLabel, value: coinAnalysis.basicInfo.country)
                infoRow(label: Constants.Text.denominationLabel, value: coinAnalysis.basicInfo.denomination)
                infoRow(label: Constants.Text.compositionLabel, value: coinAnalysis.basicInfo.composition)
            }
        }
        .padding(20)
        .background(Constants.Colors.lightGold)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }
    
    private var valueAssessmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: Constants.Text.valueAssessmentTitle, icon: "dollarsign.circle.fill")
            
            VStack(spacing: 12) {
                infoRow(label: Constants.Text.collectorValueLabel, value: coinAnalysis.valueAssessment.collectorValue.capitalized)
                infoRow(label: Constants.Text.rarityLabel, value: coinAnalysis.valueAssessment.rarity.capitalized)
            }
        }
        .padding(20)
        .background(Constants.Colors.lightGold)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: Constants.Text.descriptionTitle, icon: "text.quote")
            
            Text(coinAnalysis.description)
                .font(.body)
                .foregroundColor(Constants.Colors.textColor)
                .lineLimit(nil)
        }
        .padding(20)
        .background(Constants.Colors.lightGold)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }
    
    private var historicalContextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: Constants.Text.historicalContextTitle, icon: "book.fill")
            
            Text(coinAnalysis.historicalContext)
                .font(.body)
                .foregroundColor(Constants.Colors.textColor)
                .lineLimit(nil)
        }
        .padding(20)
        .background(Constants.Colors.lightGold)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }
    
    private var technicalDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: Constants.Text.technicalDetailsTitle, icon: "gearshape.fill")
            
            VStack(spacing: 12) {
                if let mintMark = coinAnalysis.technicalDetails.mintMark {
                    infoRow(label: Constants.Text.mintMarkLabel, value: mintMark)
                }
                infoRow(label: Constants.Text.rarityLabel, value: coinAnalysis.technicalDetails.rarity.capitalized)
                if coinAnalysis.technicalDetails.hasDiameter {
                    infoRow(label: Constants.Text.diameterLabel, value: coinAnalysis.technicalDetails.formattedDiameter)
                }
            }
        }
        .padding(20)
        .background(Constants.Colors.lightGold)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: onNewAnalysis) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(Constants.Text.analyzeAnotherTitle)
                }
                .font(.headline)
                .foregroundColor(Constants.Colors.pureWhite)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.Colors.primaryGold)
                .cornerRadius(Constants.Layout.cardCornerRadius)
            }
            
            Button(action: onBack) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text(Constants.Text.backToCameraTitle)
                }
                .font(.headline)
                .foregroundColor(Constants.Colors.textColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.Colors.lightGold)
                .cornerRadius(Constants.Layout.cardCornerRadius)
            }
        }
        .padding(.top, 20)
    }
    
    private func cardHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Constants.Colors.primaryGold)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textColor)
            
            Spacer()
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Constants.Colors.textColor.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    let sampleAnalysis = CoinAnalysis(
        basicInfo: BasicInfo(
            releasedYear: "1932",
            country: "USA",
            denomination: "25 cents",
            composition: "91.67% copper, 8.33% nickel"
        ),
        valueAssessment: ValueAssessment(
            collectorValue: "low collector value",
            rarity: "common"
        ),
        description: "This is a Washington quarter featuring George Washington. It has been minted since 1932.",
        historicalContext: "Introduced to commemorate the 200th anniversary of George Washington's birth.",
        technicalDetails: TechnicalDetails(
            mintMark: "P",
            rarity: "common",
            diameterMm: "24.26"
        )
    )
    
    return CoinAnalysisResultView(
        coinAnalysis: sampleAnalysis,
        onBack: {},
        onNewAnalysis: {}
    )
} 