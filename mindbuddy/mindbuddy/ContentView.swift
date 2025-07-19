//
//  ContentView.swift
//  mindbuddy
//
//  Created by Emerson Ferreira on 16/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingSplash = true
    
    var body: some View {
        Group {
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding && !authManager.isAuthenticated {
                OnboardingView()
                    .transition(.move(edge: .trailing))
            } else if authManager.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isShowingSplash)
        .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .onAppear {
            // Check if user is already authenticated
            if authManager.getAccessToken() != nil {
                // Could add token validation here
            }
            
            // Hide splash screen after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isShowingSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
