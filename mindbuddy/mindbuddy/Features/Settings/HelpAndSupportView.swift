import SwiftUI
import MessageUI

struct HelpAndSupportView: View {
    @State private var searchText = ""
    @State private var selectedCategory: FAQCategory? = nil
    @State private var expandedFAQ: String? = nil
    @State private var showingContactOptions = false
    @State private var showingMailComposer = false
    
    enum FAQCategory: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case healthData = "Health Data"
        case rewards = "Rewards & Tokens"
        case privacy = "Privacy & Security"
        case technical = "Technical Issues"
        
        var icon: String {
            switch self {
            case .gettingStarted: return "flag.fill"
            case .healthData: return "heart.text.square.fill"
            case .rewards: return "bitcoinsign.circle.fill"
            case .privacy: return "lock.shield.fill"
            case .technical: return "wrench.and.screwdriver.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .gettingStarted: return .blue
            case .healthData: return .red
            case .rewards: return .orange
            case .privacy: return .green
            case .technical: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search for help...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Quick Links
                    QuickLinksSection()
                    
                    // FAQ Categories
                    FAQCategoriesSection(selectedCategory: $selectedCategory)
                    
                    // FAQ Items
                    if let category = selectedCategory {
                        FAQItemsSection(
                            category: category,
                            expandedFAQ: $expandedFAQ,
                            searchText: searchText
                        )
                    }
                    
                    // Contact Support
                    ContactSupportSection(showingContactOptions: $showingContactOptions)
                    
                    // Resources
                    ResourcesSection()
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("Help & Support")
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView()
            }
            .actionSheet(isPresented: $showingContactOptions) {
                ActionSheet(
                    title: Text("Contact Support"),
                    message: Text("Choose how you'd like to reach us"),
                    buttons: [
                        .default(Text("Email Support")) {
                            showingMailComposer = true
                        },
                        .default(Text("Live Chat")) {
                            // Open live chat
                        },
                        .default(Text("Call Support")) {
                            if let url = URL(string: "tel:+1234567890") {
                                UIApplication.shared.open(url)
                            }
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}

// MARK: - Quick Links Section

struct QuickLinksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Links")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickLinkCard(
                        title: "Setup Guide",
                        icon: "book.fill",
                        color: .blue,
                        action: {}
                    )
                    
                    QuickLinkCard(
                        title: "Video Tutorials",
                        icon: "play.rectangle.fill",
                        color: .red,
                        action: {}
                    )
                    
                    QuickLinkCard(
                        title: "Community",
                        icon: "person.3.fill",
                        color: .purple,
                        action: {}
                    )
                    
                    QuickLinkCard(
                        title: "What's New",
                        icon: "sparkles",
                        color: .orange,
                        action: {}
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct QuickLinkCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - FAQ Categories Section

struct FAQCategoriesSection: View {
    @Binding var selectedCategory: HelpAndSupportView.FAQCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(HelpAndSupportView.FAQCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryCard: View {
    let category: HelpAndSupportView.FAQCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color(.systemGray6))
            )
        }
    }
}

// MARK: - FAQ Items Section

struct FAQItemsSection: View {
    let category: HelpAndSupportView.FAQCategory
    @Binding var expandedFAQ: String?
    let searchText: String
    
    var faqItems: [(question: String, answer: String)] {
        switch category {
        case .gettingStarted:
            return [
                ("How do I connect my Apple Watch?", "Open the Health app on your iPhone, tap your profile, then tap 'Devices' and follow the setup instructions."),
                ("What health data does MindBuddy track?", "MindBuddy tracks heart rate, HRV, steps, sleep, blood pressure, and active calories to calculate your stress levels and overall wellness."),
                ("How do I earn my first tokens?", "Simply share your health data! Navigate to the Health tab, select data types to share, and tap 'Submit to Earn Rewards'.")
            ]
        case .healthData:
            return [
                ("Is my health data secure?", "Yes! All your health data is encrypted end-to-end and stored securely. We are HIPAA compliant and never share your data without permission."),
                ("How often should I sync my data?", "We recommend syncing daily for the most accurate tracking and maximum rewards. You can enable daily reminders in Settings."),
                ("What if my data isn't syncing?", "Check that you've granted HealthKit permissions in Settings > Privacy > Health > MindBuddy. Try pull-to-refresh on the dashboard.")
            ]
        case .rewards:
            return [
                ("How are MNDY tokens calculated?", "Tokens are awarded based on the type and frequency of health data shared. Regular tracking earns bonus multipliers!"),
                ("When do I receive my tokens?", "Tokens are credited immediately after successful data submission. Pending rewards are shown in your dashboard."),
                ("Can I withdraw my tokens?", "Token withdrawal features are coming soon! Currently, tokens can be used within the MindBuddy ecosystem.")
            ]
        case .privacy:
            return [
                ("Who can see my health data?", "Only you can see your detailed health data. Anonymized aggregate data may be used for research if you opt-in."),
                ("How do I delete my data?", "Go to Settings > Privacy > Delete Account. This will permanently remove all your data from our servers."),
                ("Is MindBuddy GDPR compliant?", "Yes! We are fully GDPR compliant. You can export or delete your data at any time from Privacy Settings.")
            ]
        case .technical:
            return [
                ("The app is crashing, what should I do?", "Try force-quitting the app and restarting. If issues persist, reinstall the app or contact support."),
                ("Why isn't my Apple Watch connecting?", "Ensure Bluetooth is enabled, both devices are updated, and try unpairing and re-pairing your watch."),
                ("How do I update the app?", "Open the App Store, tap your profile icon, scroll to pending updates, and tap 'Update' next to MindBuddy.")
            ]
        }
    }
    
    var filteredItems: [(question: String, answer: String)] {
        if searchText.isEmpty {
            return faqItems
        }
        return faqItems.filter { item in
            item.question.localizedCaseInsensitiveContains(searchText) ||
            item.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(category.rawValue) FAQs")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(filteredItems, id: \.question) { item in
                    FAQItemRow(
                        question: item.question,
                        answer: item.answer,
                        isExpanded: expandedFAQ == item.question,
                        action: {
                            withAnimation {
                                expandedFAQ = expandedFAQ == item.question ? nil : item.question
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FAQItemRow: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isExpanded {
                    Text(answer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Contact Support Section

struct ContactSupportSection: View {
    @Binding var showingContactOptions: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Still need help?")
                .font(.headline)
            
            Text("Our support team is here to assist you")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingContactOptions = true }) {
                Label("Contact Support", systemImage: "message.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Resources Section

struct ResourcesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ResourceRow(
                    title: "MindBuddy Blog",
                    description: "Latest health insights and tips",
                    icon: "newspaper.fill",
                    action: {
                        if let url = URL(string: "https://mindbuddy.health/blog") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                
                ResourceRow(
                    title: "Developer API",
                    description: "Build with MindBuddy",
                    icon: "chevron.left.forwardslash.chevron.right",
                    action: {
                        if let url = URL(string: "https://mindbuddy.health/developers") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                
                ResourceRow(
                    title: "System Status",
                    description: "Check service availability",
                    icon: "checkmark.circle.fill",
                    action: {
                        if let url = URL(string: "https://status.mindbuddy.health") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            .padding(.horizontal)
        }
    }
}

struct ResourceRow: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let composer = MFMailComposeViewController()
            composer.setSubject("MindBuddy Support Request")
            composer.setToRecipients(["support@mindbuddy.health"])
            composer.setMessageBody("Please describe your issue:\n\n\n\n---\nApp Version: 1.0.0\nDevice: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)", isHTML: false)
            return composer
        } else {
            // Fallback if mail is not configured
            let alert = UIAlertController(
                title: "Email Not Configured",
                message: "Please configure your email in Settings or contact us at support@mindbuddy.health",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            return alert
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    HelpAndSupportView()
}