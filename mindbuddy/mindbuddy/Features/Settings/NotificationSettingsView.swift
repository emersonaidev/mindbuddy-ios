import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var dailyReminder = true
    @State private var weeklyReport = true
    @State private var rewardNotifications = true
    @State private var healthAlerts = true
    @State private var marketingUpdates = false
    
    @State private var dailyReminderTime = Date()
    @State private var quietHoursEnabled = false
    @State private var quietHoursStart = Date()
    @State private var quietHoursEnd = Date()
    
    @State private var showingPermissionAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                // Master Toggle Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            VStack(alignment: .leading) {
                                Text("Enable Notifications")
                                    .font(.body)
                                Text("Get updates about your health and rewards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            disableAllNotifications()
                        }
                    }
                }
                
                // Notification Types
                if notificationsEnabled {
                    Section("Notification Types") {
                        NotificationToggleRow(
                            title: "Daily Reminder",
                            description: "Remind me to track my health data",
                            icon: "clock.fill",
                            iconColor: .orange,
                            isOn: $dailyReminder
                        )
                        
                        if dailyReminder {
                            DatePicker(
                                "Reminder Time",
                                selection: $dailyReminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.automatic)
                            .padding(.leading, 44)
                        }
                        
                        NotificationToggleRow(
                            title: "Weekly Summary",
                            description: "Get your health insights every week",
                            icon: "chart.bar.fill",
                            iconColor: .purple,
                            isOn: $weeklyReport
                        )
                        
                        NotificationToggleRow(
                            title: "Reward Updates",
                            description: "When you earn or receive tokens",
                            icon: "bitcoinsign.circle.fill",
                            iconColor: .yellow,
                            isOn: $rewardNotifications
                        )
                        
                        NotificationToggleRow(
                            title: "Health Alerts",
                            description: "Important health metric changes",
                            icon: "heart.text.square.fill",
                            iconColor: .red,
                            isOn: $healthAlerts
                        )
                        
                        NotificationToggleRow(
                            title: "News & Updates",
                            description: "MindBuddy features and community",
                            icon: "newspaper.fill",
                            iconColor: .green,
                            isOn: $marketingUpdates
                        )
                    }
                    
                    // Quiet Hours
                    Section("Quiet Hours") {
                        Toggle(isOn: $quietHoursEnabled) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.indigo)
                                    .font(.title3)
                                
                                VStack(alignment: .leading) {
                                    Text("Enable Quiet Hours")
                                    Text("Pause notifications during specific times")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if quietHoursEnabled {
                            DatePicker(
                                "From",
                                selection: $quietHoursStart,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.automatic)
                            
                            DatePicker(
                                "To",
                                selection: $quietHoursEnd,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.automatic)
                        }
                    }
                    
                    // Notification Preview
                    Section {
                        Button(action: sendTestNotification) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .font(.body)
                                
                                Text("Send Test Notification")
                                    .font(.body)
                                
                                Spacer()
                                
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(isLoading || !notificationsEnabled)
                    } header: {
                        Text("Test")
                    } footer: {
                        Text("Send a test notification to see how it looks")
                    }
                }
            }
            .navigationTitle("Notifications")
            .alert("Notification Permission", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive updates from MindBuddy.")
            }
            .onAppear {
                checkNotificationStatus()
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    notificationsEnabled = true
                    scheduleNotifications()
                } else {
                    notificationsEnabled = false
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func disableAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleNotifications() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule daily reminder if enabled
        if dailyReminder {
            let content = UNMutableNotificationContent()
            content.title = "Time to Track Your Health"
            content.body = "Don't forget to sync your health data and earn rewards!"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "daily_reminder",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
        
        // Schedule weekly report if enabled
        if weeklyReport {
            let content = UNMutableNotificationContent()
            content.title = "Your Weekly Health Summary"
            content.body = "Check out your health insights and rewards earned this week!"
            content.sound = .default
            
            var components = DateComponents()
            components.weekday = 1 // Sunday
            components.hour = 10
            components.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "weekly_report",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func sendTestNotification() {
        isLoading = true
        
        let content = UNMutableNotificationContent()
        content.title = "MindBuddy Test"
        content.body = "This is what your notifications will look like!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { _ in
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                    .frame(width: 28)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}