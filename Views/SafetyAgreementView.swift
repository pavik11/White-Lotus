import SwiftUI

enum OnboardingTerms {
    // Reconsent existing installs after changing the brand and onboarding terms.
    static let currentVersion = 2
}

struct SafetyAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showHelp = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 36)).foregroundStyle(WellnessTheme.accent)
                            .accessibilityHidden(true)
                        Text("A space built on trust.")
                            .font(.system(.title, design: .serif, weight: .medium))
                            .foregroundStyle(WellnessTheme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("A few things to know before your first conversation.")
                            .foregroundStyle(WellnessTheme.muted)
                    }
                    termsSection("1. Your Privacy (Local-First)", symbol: "iphone", text:
                        "Your conversations belong to you. This app does not use cloud databases. Chat archives are stored on this device and excluded from device backups. To generate a reply, your messages and active conversation history are sent to Google's Gemini API. Your saved name is not added to those requests. Google's data policies apply to what you send.")
                    termsSection("2. The Safety Net", symbol: "heart.text.clipboard", text:
                        "While your chats are private, your life is our highest priority. The app uses an automated, on-device keyword scanner. If you express thoughts of self-harm, suicide, or extreme danger, the AI will immediately pause the conversation and provide you with professional emergency resources (like the 988 Lifeline).")
                    Text("The keyword scanner can miss danger or flag everyday phrases. Help now is always available. The 988 resource is for the United States.")
                        .font(.footnote).foregroundStyle(WellnessTheme.muted)
                    termsSection("3. Not a Substitute for Medical Care", symbol: "cross.case", text:
                        "This app provides AI companions designed for venting, motivation, and emotional support. It is not a licensed therapist or medical professional. It cannot diagnose or treat clinical mental health conditions.")
                    Link("Google Gemini API data policies", destination: URL(string: "https://ai.google.dev/gemini-api/terms")!)
                        .font(.subheadline).frame(minHeight: 44)
                    Button("Help now") { showHelp = true }
                        .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
                .padding(26).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .background(WellnessTheme.welcomeBackground)
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("termsDone")
                }
            }
        }
        .fullScreenCover(isPresented: $showHelp) { CrisisInterventionView() }
    }

    private func termsSection(_ title: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline).foregroundStyle(WellnessTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Text(text).font(.body).foregroundStyle(WellnessTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
