import SwiftUI

// Para facilitar, podemos definir as cores exatas do design aqui.
// Estes são valores aproximados baseados na imagem.
extension Color {
    static let darkPurpleBackground = Color(red: 44/255, green: 20/255, blue: 68/255)
    static let lightPurpleBackground = Color(red: 74/255, green: 43/255, blue: 106/255)
    static let cardBackground = Color.white.opacity(0.1)
    static let numberCircleBackground = Color.white.opacity(0.15)
}

struct OnboardingHowItWorksView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.0588, green: 0.0549, blue: 0.102)
                .ignoresSafeArea()

            // Overlays - same as WelcomeView
            ZStack {
                Circle()
                    .fill(Color(red: 0.3098, green: 0.2745, blue: 0.898))
                    .opacity(0.3)
                    .frame(width: 600, height: 900)
                    .blur(radius: 64)
                    .offset(x: -50, y: -69)

                Circle()
                    .fill(Color(red: 0.7529, green: 0.149, blue: 0.8275))
                    .opacity(0.25)
                    .frame(width: 600, height: 900)
                    .blur(radius: 64)
                    .offset(x: -80, y: 360)
            }
            .ignoresSafeArea()
            .drawingGroup()
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header (Back Button)
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
                .padding(.leading)
                .padding(.top)

                // MARK: - Main Title
                Text("How it works")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 30)

                // MARK: - Info Cards
                VStack(spacing: 20) {
                    InfoCardView(
                        number: "1",
                        title: "Collect real-world data",
                        description: "We connect to your phone or wearable to track signals like HRV and sleep."
                    )

                    InfoCardView(
                        number: "2",
                        title: "Earn $MNDY tokens",
                        description: "Get rewarded for consistently sharing high-quality stress data."
                    )

                    InfoCardView(
                        number: "3",
                        title: "Enrich research",
                        description: "Your signals contribute to the world's largest real-world stress dataset."
                    )
                }
                .padding(.top, 40)
                .padding(.horizontal)

                Spacer() // Empurra tudo para cima

                // MARK: - Page Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .frame(maxWidth: .infinity) // Centraliza o HStack
                .padding(.bottom, 20)


                // MARK: - Bottom Button
                Button(action: {
                    // Adicione a ação para o botão "Next" aqui
                }) {
                    Text("Next")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.bottom)

            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Reusable Info Card View
struct InfoCardView: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.numberCircleBackground)
                    .frame(width: 40, height: 40)
                Text(number)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4) // Melhora a legibilidade para texto com mais de uma linha
            }
            Spacer() // Garante que o conteúdo não se estica desnecessariamente
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
    }
}

// MARK: - Preview
#Preview {
    OnboardingHowItWorksView()
}
