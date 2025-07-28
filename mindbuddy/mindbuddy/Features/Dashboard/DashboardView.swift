import SwiftUI

// MARK: - Main Dashboard View
struct DashboardView: View {
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            // Fundo principal
            Color(hex: "0f0e1a").ignoresSafeArea()

            // Gradientes de fundo desfocados
            backgroundGradients

            ScrollView {
                VStack(spacing: 32) { // mt-8 -> spacing
                    HeaderView()
                    BalanceCardView()
                    ResilienceCardView()
                    ReputationCardView()
                    WeeklySummaryCardView()
                    RecentActivityCardView()
                }
                .padding(.horizontal, 24) // pl-6, pr-6
                .padding(.top, 64) // pt-16
                .padding(.bottom, 120) // pb-24 + espaço extra para a nav bar
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 12)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                        hasAppeared = true
                    }
                }
            }
            .frame(width: 393) // Largura fixa
            
            // Barra de Navegação Inferior
            VStack {
                Spacer()
                BottomNavBarView()
            }
            .frame(width: 393)
        }
        .foregroundColor(.white)
        .font(.custom("Inter-Regular", size: 16))
    }
    
    // Vista para os círculos de gradiente de fundo
    private var backgroundGradients: some View {
        ZStack {
            Circle()
                .fill(Color.indigo.opacity(0.30))
                .frame(width: 520, height: 520)
                .blur(radius: 96) // blur-3xl
                .offset(x: -96, y: -128) // -left-24, -top-32

            Circle()
                .fill(Color.purple.opacity(0.25)) // Fuchsia é próximo a roxo
                .frame(width: 620, height: 620)
                .blur(radius: 96) // blur-3xl
                .offset(x: 80, y: 128) // -right-20, -bottom-32
        }
        .allowsHitTesting(false)
    }
}


// MARK: - Reusable Card Background Modifier
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20)) // px-5, py-6
            .background(.ultraThinMaterial.opacity(0.8)) // bg-white/5 + backdrop-blur-md
            .cornerRadius(16) // rounded-2xl
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1) // ring-1 ring-white/10
            )
    }
}

// MARK: - 🧭 Top Navigation
struct HeaderView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        HStack {
            Text("Dashboard")
                .font(.custom("Inter-SemiBold", size: 20))
            Spacer()
            Menu {
                Button(action: {
                    authManager.logout()
                }) {
                    Label("Sign Out", systemImage: "arrow.backward.circle")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
    }
}

// MARK: - 💰 $MNDY Balance Section
struct BalanceCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("$MNDY Balance")
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("+12 today")
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundColor(Color(hex: "34d399")) // green-400
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "34d399").opacity(0.1))
                    .cornerRadius(12)
            }
            Text("247 $MNDY")
                .font(.custom("Inter-SemiBold", size: 26))
                .tracking(-0.5)
                .padding(.top, 16)
            
            Text("Recent earnings breakdown")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
            
            VStack(spacing: 8) {
                EarningRow(icon: "moon.fill", label: "Sleep:", value: "+3")
                EarningRow(icon: "waveform.path.ecg", label: "HRV:", value: "+4")
                EarningRow(icon: "figure.walk", label: "Steps:", value: "+5")
            }
            .padding(.top, 16)
        }
        .modifier(CardBackground())
    }
}

struct EarningRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .opacity(0.6)
            Text(label)
                .font(.system(size: 14))
            Spacer()
            Text(value)
                .font(.custom("Inter-Medium", size: 14))
        }
    }
}

// MARK: - 🧠 Resilience Score Section
struct ResilienceCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resilience Score")
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.2))
                    Text("72")
                        .font(.custom("Inter-SemiBold", size: 26))
                }
                .frame(width: 80, height: 80)
                
                Text("High")
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(Color(hex: "34d399"))
                    .padding(.top, 8)
                    
                HStack(spacing: 4) {
                    Circle().fill(.white).frame(width: 6, height: 6)
                    Circle().fill(.white.opacity(0.3)).frame(width: 6, height: 6)
                    Circle().fill(.white.opacity(0.3)).frame(width: 6, height: 6)
                }
                .padding(.top, 12)
                
                Button("What does this mean?") {
                    // Action
                }
                .font(.system(size: 12))
                .foregroundColor(Color.indigo.opacity(0.8))
                .underline()
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
        }
        .modifier(CardBackground())
    }
}

// MARK: - 📊 Data Reputation Score Section
struct ReputationCardView: View {
    let progress: Double = 0.85

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Reputation Score")
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(Int(progress * 100))%")
                .font(.custom("Inter-SemiBold", size: 26))
                .tracking(-0.5)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    Capsule()
                        .fill(Color.indigo)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("Your data quality and consistency rating based on device connectivity and measurement accuracy")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(4)
        }
        .modifier(CardBackground())
    }
}

// MARK: - 📅 Weekly Summary Section
struct WeeklySummaryCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Weekly Summary")
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))

            Grid(horizontalSpacing: 24, verticalSpacing: 16) {
                GridRow {
                    SummaryItem(value: "26", label: "Total $MNDY")
                    SummaryItem(value: "7", label: "Active Days")
                }
                GridRow {
                    SummaryItem(value: "4.2", label: "Avg Daily")
                    SummaryItem(value: "92%", label: "Data Quality")
                }
            }
        }
        .modifier(CardBackground())
    }
}

struct SummaryItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("Inter-SemiBold", size: 20))
                .tracking(-0.5)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 🕒 Recent Activity Section
struct RecentActivityCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 0) {
                ActivityRow(icon: "moon.fill", title: "Sleep Quality", value: "+3 $MNDY", time: "2 hours ago")
                Divider().background(Color.white.opacity(0.1))
                ActivityRow(icon: "waveform.path.ecg", title: "HRV Measurement", value: "+4 $MNDY", time: "4 hours ago")
                Divider().background(Color.white.opacity(0.1))
                ActivityRow(icon: "figure.walk", title: "Daily Steps", value: "+5 $MNDY", time: "6 hours ago")
            }
        }
        .modifier(CardBackground())
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let value: String
    let time: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .opacity(0.7)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 14))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.custom("Inter-Medium", size: 14))
                Text(time)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 12)
    }
}


// MARK: - Bottom Navigation Bar
struct BottomNavBarView: View {
    var body: some View {
        HStack {
            Spacer()
            NavItem(icon: "house.fill", label: "Home", isActive: true)
            Spacer()
            NavItem(icon: "gear", label: "Settings")
            Spacer()
            NavItem(icon: "questionmark.circle", label: "Help")
            Spacer()
            NavItem(icon: "scalemass", label: "Legal")
            Spacer()
            NavItem(icon: "person", label: "Profile")
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
        .clipShape(Capsule()) // rounded-full
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 24) // px-6
        .padding(.bottom, 24) // pb-6
    }
}

struct NavItem: View {
    let icon: String
    let label: String
    var isActive: Bool = false

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(isActive ? Color.indigo.opacity(0.8) : .white.opacity(0.7))
        }
    }
}


// MARK: - Preview Provider
#Preview {
    DashboardView()
}