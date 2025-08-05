import SwiftUI

struct AppPrivacyPolicy: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.Colors.textColor)
                        
                        Text("Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Introduction
                    PrivacySection(
                        title: "Introduction",
                        content: "Welcome to CopperZync. We respect your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your information when you use our coin identification app."
                    )
                    
                    // Information We Collect
                    PrivacySection(
                        title: "Information We Collect",
                        content: """
                        • **Camera Photos**: Photos you capture for coin identification are processed temporarily and not stored on our servers
                        • **Device Information**: Basic device info for app compatibility and support
                        • **Usage Data**: Anonymous usage patterns to improve our service
                        """
                    )
                    
                    // How We Use Information
                    PrivacySection(
                        title: "How We Use Your Information",
                        content: """
                        • **Coin Identification**: Process photos using AI to identify coins
                        • **Service Improvement**: Use anonymous data to enhance app performance
                        • **Technical Support**: Resolve app issues and provide assistance
                        """
                    )
                    
                    // Data Security
                    PrivacySection(
                        title: "Data Security",
                        content: """
                        • **Encryption**: All data transmission is encrypted
                        • **Temporary Processing**: Images are processed temporarily and not stored permanently
                        • **Local Control**: Photos saved to your device remain under your control
                        """
                    )
                    
                    // Your Rights
                    PrivacySection(
                        title: "Your Rights and Choices",
                        content: """
                        • **Camera Access**: You control camera permissions
                        • **Photo Library**: You choose whether to save photos
                        • **No Personal Data**: We don't store personal information requiring deletion
                        """
                    )
                    
                    // Children's Privacy
                    PrivacySection(
                        title: "Children's Privacy",
                        content: "Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13."
                    )
                    
                    // Contact Information
                    PrivacySection(
                        title: "Contact Us",
                        content: """
                        If you have questions about this Privacy Policy, please contact us:
                        
                        Developer: Altynbek Kenzhe
                        Email: [Your Contact Email]
                        """
                    )
                    
                    // Footer Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Constants.Colors.textColor)
                        
                        Text("This privacy policy is specific to CopperZync. The app is designed with privacy in mind, focusing on temporary image processing for coin identification without storing personal user data.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Constants.Colors.backgroundCream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.primaryGold)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textColor)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AppPrivacyPolicy()
} 