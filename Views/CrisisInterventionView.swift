import SwiftUI

struct CrisisInterventionView: View {
    @Environment(\.dismiss) private var dismiss
    var onReturnHome: (() -> Void)? = nil

    // Contact number verified using the helpline directory. Native phone/message URL schemes
    // use only the verified number (Apple's SMS scheme disallows other information).
    // These buttons work independently of the Gemini API key.
    private let callURL = URL(string: "tel:988")!
    private let textURL = URL(string: "sms:988")!
    private let chatURL = URL(string: "https://988lifeline.org/chat/?oai_link_source=model_response_hotline")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 62)).foregroundStyle(WellnessTheme.accent)
                    .padding(.top, 32).accessibilityHidden(true)
                Text("You deserve\nhuman support.")
                    .font(.system(.largeTitle, design: .serif, weight: .medium))
                    .foregroundStyle(WellnessTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("crisisTitle")
                Text("Let's pause the AI conversation. You don't have to handle this moment alone.")
                    .font(.title3).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 18) {
                    Text("988 Suicide & Crisis Lifeline").font(.headline)
                    Text("For people in the United States and its territories. Connect with a crisis counselor by phone, text, or online chat.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Link(destination: callURL) {
                        Label("Call 988", systemImage: "phone.fill")
                    }.buttonStyle(PrimaryButtonStyle())
                    Link(destination: textURL) {
                        Label("Text 988", systemImage: "message.fill")
                            .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                            .background(Persona.teacup.surface, in: RoundedRectangle(cornerRadius: 17))
                    }
                    Link(destination: chatURL) {
                        Label("Chat online with 988", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
                .padding(22).background(WellnessTheme.card, in: RoundedRectangle(cornerRadius: 24))

                Text("If you are in immediate danger, contact local emergency services. If you can, reach out to a trusted adult or someone nearby. Outside the U.S., contact a local crisis service.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Phone and text need a supported device and service. Online chat needs internet access.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Return to companions") {
                    dismiss()
                    onReturnHome?()
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48).padding(.bottom, 24)
                .accessibilityIdentifier("crisisReturn")
            }
            .padding(.horizontal, 26).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(WellnessTheme.background)
        .interactiveDismissDisabled()
    }
}
