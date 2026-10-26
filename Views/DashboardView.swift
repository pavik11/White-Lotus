import SwiftUI

struct DashboardView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("safetyAgreementVersion") private var agreementVersion = 0
    @State private var showHelp = false
    @State private var showSettings = false
    @State private var logOutRequested = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                        Text("YOUR DAILY PAUSE").tracking(2).fontWeight(.semibold)
                    }
                    .font(.caption).foregroundStyle(WellnessTheme.accent)
                    .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hi, \(userName).")
                            .font(.system(.largeTitle, design: .serif, weight: .medium))
                            .foregroundStyle(WellnessTheme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("What do you need\na little more of today?")
                            .font(.title2).foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Persona.allCases) { persona in
                            PersonaCard(persona: persona)
                        }
                    }
                    SupportCaption().padding(.vertical, 10)
                }
                .padding(.horizontal, 22).padding(.bottom, 22)
                .frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(WellnessTheme.background)
            .navigationTitle("White Lotus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Help now") { showHelp = true }.font(.subheadline.weight(.semibold))
                }
            }
            .navigationDestination(for: Persona.self) { persona in ChatView(persona: persona) }
        }
        .fullScreenCover(isPresented: $showHelp) { CrisisInterventionView() }
        .sheet(isPresented: $showSettings, onDismiss: {
            // Wait until the settings sheet closes before replacing its dashboard presenter.
            guard logOutRequested else { return }
            logOutRequested = false
            agreementVersion = 0
            userName = ""
        }) {
            SettingsView {
                logOutRequested = true
                showSettings = false
            }
        }
    }
}

private struct PersonaCard: View {
    let persona: Persona
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: persona) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(persona.symbol).font(.system(size: 50))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8).accessibilityHidden(true)
                    Text(persona.title).font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(persona.subtitle).font(.subheadline)
                        .foregroundStyle(persona.tint.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 175, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(persona.name). \(persona.title). \(persona.subtitle)")
            .accessibilityIdentifier("persona_\(persona.rawValue)")

            Divider().overlay(persona.tint.opacity(0.1)).padding(.vertical, 6)
            Button { expanded.toggle() } label: {
                HStack {
                    Text("Learn More").font(.caption.weight(.semibold))
                    Spacer(minLength: 2)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption2)
                }
                .frame(minHeight: 38).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Learn more about \(persona.name)")
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded {
                Text(persona.details).font(.caption).padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(persona.tint)
        .padding(17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(persona.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}
