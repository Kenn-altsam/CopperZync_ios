import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 4) {
                            Text(Constants.Text.appName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Constants.Colors.textColor)
                            
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // Settings Sections
                    VStack(spacing: 24) {
                        // App Information
                        SettingsSection(title: "App Information") {
                            SettingsRow(
                                icon: "info.circle.fill",
                                title: "About CopperZync",
                                subtitle: "Learn more about the app",
                                action: { /* Add about action */ }
                            )
                            
                            SettingsRow(
                                icon: "star.fill",
                                title: "Rate the App",
                                subtitle: "Share your feedback",
                                action: { /* Add rate action */ }
                            )
                            
                            SettingsRow(
                                icon: "square.and.arrow.up",
                                title: "Share App",
                                subtitle: "Tell friends about CopperZync",
                                action: { /* Add share action */ }
                            )
                        }
                        
                        // Privacy & Legal
                        SettingsSection(title: "Privacy & Legal") {
                            SettingsRow(
                                icon: "hand.raised.fill",
                                title: "Privacy Policy",
                                subtitle: "How we protect your data",
                                action: { showPrivacyPolicy = true }
                            )
                            
                            SettingsRow(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                subtitle: "App usage terms and conditions",
                                action: { showTermsOfService = true }
                            )
                        }
                        
                        // Support
                        SettingsSection(title: "Support") {
                            SettingsRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & FAQ",
                                subtitle: "Get help with the app",
                                action: { /* Add help action */ }
                            )
                            
                            SettingsRow(
                                icon: "envelope.fill",
                                title: "Contact Us",
                                subtitle: "Get in touch with support",
                                action: { /* Add contact action */ }
                            )
                        }
                        
                        // Developer Info
                        SettingsSection(title: "Developer") {
                            SettingsRow(
                                icon: "person.fill",
                                title: "Developer",
                                subtitle: "Altynbek Kenzhe",
                                action: { /* Add developer info */ }
                            )
                            
                            SettingsRow(
                                icon: "heart.fill",
                                title: "Made with ❤️",
                                subtitle: "For coin enthusiasts",
                                action: { /* Add made with love */ }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
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
        .sheet(isPresented: $showPrivacyPolicy) {
            AppPrivacyPolicy()
        }
        .sheet(isPresented: $showTermsOfService) {
            AppTermsOfService()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Constants.Colors.pureWhite)
            .cornerRadius(Constants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Constants.Colors.primaryGold)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Constants.Colors.textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        
        // Divider (except for last item)
        if title != "Made with ❤️" {
            Divider()
                .padding(.leading, 60)
        }
    }
}

#Preview {
    SettingsView()
} 