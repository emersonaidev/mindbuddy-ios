import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.94, blue: 1.0),
                    Color(red: 0.93, green: 0.91, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo with animation
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            scale = 1.1
                            opacity = 1.0
                        }
                    }
                
                // App name
                Text("MindBuddy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(opacity)
                
                // Tagline
                Text("Your Wellness Journey Starts Here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(opacity)
                    .padding(.top, 5)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(1.2)
                    .padding(.top, 40)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}