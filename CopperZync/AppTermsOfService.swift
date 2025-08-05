import SwiftUI

struct AppTermsOfService: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.Colors.textColor)
                        
                        Text("Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Acceptance of Terms
                    TermsSection(
                        title: "Acceptance of Terms",
                        content: "By downloading, installing, or using CopperZync, you agree to be bound by these Terms of Service. If you do not agree to these Terms, do not use the App."
                    )
                    
                    // Description of Service
                    TermsSection(
                        title: "Description of Service",
                        content: """
                        CopperZync is a mobile application that uses artificial intelligence to identify coins through camera photos. The App provides:
                        • Coin identification through photo analysis
                        • Detailed information about identified coins
                        • Photo capture and management capabilities
                        • Educational content about coins and numismatics
                        """
                    )
                    
                    // User Eligibility
                    TermsSection(
                        title: "User Eligibility",
                        content: """
                        • You must be at least 13 years old to use the App
                        • You must have the legal capacity to enter into these Terms
                        • You must comply with all applicable laws and regulations
                        """
                    )
                    
                    // User Responsibilities
                    TermsSection(
                        title: "User Responsibilities",
                        content: """
                        **Acceptable Use:**
                        • Use the App only for lawful purposes
                        • Do not attempt to reverse engineer or modify the App
                        • Do not interfere with App functionality
                        
                        **Photo Content:**
                        • Only photograph coins or numismatic items
                        • Respect privacy and rights of others
                        • Do not photograph sensitive information
                        
                        **Device Requirements:**
                        • Maintain compatible device and operating system
                        • Keep device secure and updated
                        • Manage device storage and permissions
                        """
                    )
                    
                    // Intellectual Property
                    TermsSection(
                        title: "Intellectual Property",
                        content: """
                        **App Ownership:**
                        The App and its content are owned by the developer and protected by intellectual property laws.
                        
                        **User Content:**
                        You retain ownership of photos you capture. You grant us a limited license to process photos for coin identification.
                        
                        **Restrictions:**
                        You may not copy, distribute, or create derivative works based on the App.
                        """
                    )
                    
                    // Service Availability
                    TermsSection(
                        title: "Service Availability",
                        content: """
                        • The App is provided "as is" and "as available"
                        • We do not guarantee uninterrupted service
                        • Service may be temporarily unavailable for maintenance
                        • We reserve the right to modify or discontinue the service
                        """
                    )
                    
                    // Disclaimers
                    TermsSection(
                        title: "Disclaimers and Limitations",
                        content: """
                        **Accuracy of Results:**
                        • Results are provided for informational purposes only
                        • We do not guarantee accuracy of identification
                        • Results should not be used as sole basis for financial decisions
                        
                        **No Professional Advice:**
                        • The App does not provide professional advice
                        • Information is for educational purposes only
                        • Consult qualified professionals for important decisions
                        """
                    )
                    
                    // Privacy
                    TermsSection(
                        title: "Privacy and Data Protection",
                        content: "Your privacy is important to us. Our collection and use of your information is governed by our Privacy Policy, which is incorporated into these Terms by reference."
                    )
                    
                    // Contact Information
                    TermsSection(
                        title: "Contact Us",
                        content: """
                        For questions about these Terms of Service, please contact us:
                        
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
                        
                        Text("These Terms of Service are specific to the CopperZync coin identification app. By using the App, you acknowledge that you have read, understood, and agree to be bound by these Terms.")
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

struct TermsSection: View {
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
    AppTermsOfService()
} 