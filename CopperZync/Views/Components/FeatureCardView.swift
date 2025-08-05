import SwiftUI

struct FeatureCardView: View {
    let feature: FeatureCard
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.iconColor)
                    .frame(width: Constants.Layout.iconSize, height: Constants.Layout.iconSize)
                
                Image(systemName: feature.icon)
                    .foregroundColor(Constants.Colors.pureWhite)
                    .font(.system(size: 20, weight: .medium))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textColor)
                    .fontWeight(.semibold)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(Constants.Colors.textColor.opacity(0.8))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(Constants.Layout.verticalPadding)
        .background(Color(hex: "F6C65B"))
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    FeatureCardView(feature: FeatureCard.sampleFeatures[0])
        .padding()
} 
