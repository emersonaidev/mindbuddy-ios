//
//  mindbuddyApp.swift
//  mindbuddy
//
//  Created by Emerson Ferreira on 16/07/2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Check if GoogleService-Info.plist exists
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("⚠️ GoogleService-Info.plist not found. Firebase SSO will not work.")
            return true
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("⚠️ CLIENT_ID not found in GoogleService-Info.plist")
            return true
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        print("✅ Firebase and Google Sign-In configured successfully")
        return true
    }
    
    // Handle Google Sign-In URL schemes
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct mindbuddyApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize dependency container
    private let dependencies = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupBackgroundTasks()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleAppWillEnterForeground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
        }
    }
    
    private func setupBackgroundTasks() {
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
    
    private func handleAppWillEnterForeground() {
        BackgroundTaskManager.shared.handleAppWillEnterBackground()
    }
    
    private func handleAppDidBecomeActive() {
        BackgroundTaskManager.shared.handleAppDidBecomeActive()
    }
}
