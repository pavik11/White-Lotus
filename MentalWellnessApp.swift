import SwiftUI

@main
struct MentalWellnessApp: App {
    private let preferences: UserDefaults

    init() {
        #if DEBUG
        let usesIsolatedState = ProcessInfo.processInfo.environment["WELLNESS_ISOLATED_TEST_STATE"] == "1"
        #else
        let usesIsolatedState = false
        #endif
        let domain = Bundle.main.bundleIdentifier ?? "WhiteLotus"
        let preferencesDomain = usesIsolatedState ? domain + ".UITests" : domain
        preferences = usesIsolatedState ? (UserDefaults(suiteName: preferencesDomain) ?? .standard) : .standard
        #if DEBUG
        // A debug-only test hook resets onboarding without putting real data or keys in tests.
        if ProcessInfo.processInfo.environment["WELLNESS_RESET_PREFERENCES"] == "1" {
            preferences.removePersistentDomain(forName: preferencesDomain)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .defaultAppStorage(preferences)
                .tint(WellnessTheme.accent)
                // The palette is intentionally light; explicit surfaces keep contrast predictable.
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("safetyAgreementVersion") private var agreementVersion = 0

    var body: some View {
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || agreementVersion < OnboardingTerms.currentVersion {
            WelcomeView()
        } else {
            DashboardView()
        }
    }
}
