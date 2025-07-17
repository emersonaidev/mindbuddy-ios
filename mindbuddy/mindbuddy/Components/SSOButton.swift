import SwiftUI

struct SSOButton: View {
    let provider: SSOProvider
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: provider.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: provider.iconName)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text("Continue with \(provider.displayName)")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(provider.foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(provider.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(provider.borderColor, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

enum SSOProvider {
    case google
    case apple
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }
    
    var iconName: String {
        switch self {
        case .google:
            return "globe"
        case .apple:
            return "applelogo"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .google:
            return Color.white
        case .apple:
            return Color.black
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .google:
            return Color.black
        case .apple:
            return Color.white
        }
    }
    
    var borderColor: Color {
        switch self {
        case .google:
            return Color.gray.opacity(0.3)
        case .apple:
            return Color.clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SSOButton(provider: .google, action: {}, isLoading: false)
        SSOButton(provider: .apple, action: {}, isLoading: true)
        SSOButton(provider: .google, action: {}, isLoading: true)
        SSOButton(provider: .apple, action: {}, isLoading: false)
    }
    .padding()
}