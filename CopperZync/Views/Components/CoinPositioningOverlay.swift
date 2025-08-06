import SwiftUI

struct CoinPositioningOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay with cutout circle
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .mask(
                    ZStack {
                        Rectangle()
                        Circle()
                            .frame(width: 280, height: 280)
                            .blendMode(.destinationOut)
                    }
                )
            
            // Circle border with animation
            Circle()
                .stroke(Constants.Colors.primaryGold, lineWidth: 3)
                .frame(width: 280, height: 280)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .opacity(isAnimating ? 0.8 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Corner guides
            VStack(spacing: 200) {
                HStack(spacing: 200) {
                    // Top-left corner
                    CornerGuide()
                    // Top-right corner
                    CornerGuide()
                        .rotationEffect(.degrees(90))
                }
                
                HStack(spacing: 200) {
                    // Bottom-left corner
                    CornerGuide()
                        .rotationEffect(.degrees(-90))
                    // Bottom-right corner
                    CornerGuide()
                        .rotationEffect(.degrees(180))
                }
            }
            
            // Center dot
            Circle()
                .fill(Constants.Colors.primaryGold)
                .frame(width: 8, height: 8)
                .opacity(0.8)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CornerGuide: View {
    var body: some View {
        ZStack {
            // Outer arc
            Arc(startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                .stroke(Constants.Colors.primaryGold, lineWidth: 3)
                .frame(width: 60, height: 60)
            
            // Inner arc
            Arc(startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                .stroke(Constants.Colors.primaryGold, lineWidth: 2)
                .frame(width: 40, height: 40)
        }
    }
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        
        return path
    }
}

#Preview {
    ZStack {
        Color.gray
        CoinPositioningOverlay()
    }
} 