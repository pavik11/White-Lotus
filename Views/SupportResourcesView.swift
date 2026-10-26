import SwiftUI

struct SupportRecommendationCard: View {
    let topic: SupportTopic
    var onBrowse: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("People can help, too", systemImage: "person.2.fill")
                .font(.headline).foregroundStyle(WellnessTheme.ink)
            Text(topic.introduction).font(.subheadline)
            Text("U.S. resources · Optional support")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(topic.resources) { resource in
                VStack(alignment: .leading, spacing: 6) {
                    Text(resource.name).font(.subheadline.weight(.semibold))
                    Text(resource.summary).font(.footnote).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(destination: resource.website) {
                        Label("Visit \(resource.name)", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .accessibilityIdentifier("support_\(resource.id)")
                }
            }
            if let onBrowse = onBrowse {
                Button("Find other support", action: onBrowse)
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(WellnessTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
    }
}

struct SupportResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topic: SupportTopic
    private let onUrgent: () -> Void

    init(initialTopic: SupportTopic = .connection, onUrgent: @escaping () -> Void) {
        _topic = State(initialValue: initialTopic)
        self.onUrgent = onUrgent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("You can choose more support.")
                        .font(.system(.title2, design: .serif, weight: .medium))
                        .foregroundStyle(WellnessTheme.ink)
                    Text("Choose what fits. These U.S. organizations offer different kinds of help. Opening a resource doesn't send your chat history or saved name.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Picker("What would you like help with?", selection: $topic) {
                        ForEach(SupportTopic.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("supportTopicPicker")
                    SupportRecommendationCard(topic: topic)
                    Text("If you mean physically lost or stranded, contact a trusted adult or someone nearby who can help. If you're in immediate danger, contact local emergency services.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("I need urgent support") {
                        onUrgent()
                        dismiss()
                    }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("supportUrgentHelp")
                    Text("Outside the U.S., use a local support service. Check each organization's website for current hours and eligibility. Links reviewed October 25, 2026.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(22).frame(maxWidth: 650).frame(maxWidth: .infinity)
            }
            .background(WellnessTheme.welcomeBackground)
            .navigationTitle("Human support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("supportDone")
                }
            }
        }

    }
}
