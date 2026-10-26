import SwiftUI

struct WelcomeView: View {
    @AppStorage("userName") private var storedName = ""
    @AppStorage("safetyAgreementVersion") private var agreementVersion = 0
    @State private var name = ""
    @State private var acceptedTerms = false
    @State private var showTerms = false
    @State private var showHelp = false
    @FocusState private var nameIsFocused: Bool

    private var canBegin: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && acceptedTerms
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("WHITE LOTUS")
                    .font(.caption.weight(.semibold)).tracking(4)
                    .foregroundStyle(WellnessTheme.accent)
                    .padding(.top, 18)

                LotusEmblem()
                    .frame(height: 128)
                    .padding(.top, 10)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Welcome to\nWhite Lotus")
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                        .foregroundStyle(WellnessTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("welcomeTitle")
                    Text("A little room to breathe.\nA companion for however you feel.")
                        .font(.body).foregroundStyle(WellnessTheme.muted)
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What would you like to be called?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WellnessTheme.ink)
                    TextField("Your preferred name", text: $name)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(18)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(WellnessTheme.accent.opacity(nameIsFocused ? 0.65 : 0.16), lineWidth: 1))
                        .focused($nameIsFocused)
                        .onSubmit { nameIsFocused = false }
                        .onChange(of: name) { value in
                            if value.count > 40 { name = String(value.prefix(40)) }
                        }
                        .accessibilityLabel("Your preferred name")
                        .accessibilityIdentifier("preferredName")
                    Text("Your name stays on this device and isn't added to AI requests.")
                        .font(.caption).foregroundStyle(WellnessTheme.muted)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        nameIsFocused = false
                        acceptedTerms.toggle()
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                .font(.title2).foregroundStyle(WellnessTheme.accent)
                            Text("I accept the Terms & Conditions.")
                                .font(.subheadline).foregroundStyle(WellnessTheme.ink)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Accept Terms and Conditions")
                    .accessibilityValue(acceptedTerms ? "Checked" : "Unchecked")
                    .accessibilityIdentifier("safetyCheckbox")

                    Button("Read Terms") {
                        nameIsFocused = false
                        showTerms = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .padding(.leading, 36)
                    .accessibilityIdentifier("readTerms")
                }

                Button(action: beginJourney) {
                    HStack(spacing: 10) {
                        Spacer()
                        Text("Begin Journey")
                        Image(systemName: "arrow.right").font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canBegin)
                .accessibilityIdentifier("beginJourney")

                VStack(spacing: 8) {
                    Text("A gentle companion. One moment at a time.")
                        .font(.caption).foregroundStyle(WellnessTheme.muted)
                    Button("Help now") { showHelp = true }
                        .font(.caption.weight(.semibold)).frame(minHeight: 44)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(WellnessTheme.welcomeBackground.ignoresSafeArea())
        .onAppear { name = storedName }
        .sheet(isPresented: $showTerms) { SafetyAgreementView() }
        .fullScreenCover(isPresented: $showHelp) { CrisisInterventionView() }
    }

    private func beginJourney() {
        guard canBegin else { return }
        nameIsFocused = false
        storedName = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        agreementVersion = OnboardingTerms.currentVersion
    }
}

// Native vector petals stay crisp at every display scale and require no image download.
struct LotusEmblem: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(red: 0.81, green: 0.89, blue: 0.80).opacity(0.75), .clear],
                                     center: .center, startRadius: 18, endRadius: 90))
                .frame(width: 200, height: 200)
            ForEach([-55.0, 55, -30, 30, 0], id: \.self) { angle in
                Ellipse()
                    .fill(LinearGradient(colors: [.white, Color(red: 0.86, green: 0.92, blue: 0.85)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(Ellipse().stroke(WellnessTheme.accent.opacity(0.15), lineWidth: 1))
                    .frame(width: 48, height: 94)
                    .offset(y: -38)
                    .rotationEffect(.degrees(angle), anchor: .center)
            }
            Ellipse()
                .fill(WellnessTheme.accent.opacity(0.24))
                .frame(width: 74, height: 9)
                .offset(y: 25)
        }
        .shadow(color: WellnessTheme.accent.opacity(0.08), radius: 12, y: 8)
    }
}
