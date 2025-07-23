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
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                LoginView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.move(edge: .trailing))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .onAppear {
            // Check if user is already authenticated
            if authManager.getAccessToken() != nil {
                // Could add token validation here
            }
        }
    }
}

#Preview {
    ContentView()
}
