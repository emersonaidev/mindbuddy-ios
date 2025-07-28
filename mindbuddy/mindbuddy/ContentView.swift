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
                DashboardView()
            } else {
                NavigationStack {
                    WelcomeView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}