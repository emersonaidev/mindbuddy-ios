//
//  ContentView.swift
//  mindbuddy
//
//  Created by Emerson Ferreira on 16/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
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
