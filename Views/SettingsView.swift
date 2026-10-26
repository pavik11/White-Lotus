import SwiftUI

struct SettingsView: View {
    let onLogOut: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName = ""
    @State private var editedName = ""
    @State private var showTerms = false
    @State private var confirmDeletion = false
    @State private var status: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Your name") {
                    TextField("Preferred name", text: $editedName)
                        .textContentType(.givenName)
                        .onChange(of: editedName) { value in
                            if value.count > 40 { editedName = String(value.prefix(40)) }
                        }
                    Button("Save name") {
                        userName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        status = "Your name has been updated."
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Section {
                    Button(action: onLogOut) {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityIdentifier("logOut")
                } header: {
                    Text("Start fresh")
                } footer: {
                    Text("Return to the welcome screen and reset your name and consent. Saved chats stay on this device.")
                }
                Section {
                    Text("Chat archives stay in this app's local storage and are excluded from backups. Returning home clears the active AI conversation; it does not delete the archive.")
                    Button("Delete all saved chats", role: .destructive) { confirmDeletion = true }
                } header: { Text("On-device archives") }
                Section("AI & privacy") {
                    Button("Read Terms & Conditions") { showTerms = true }
                    Text("Messages and active history are sent to Google's Gemini API for replies. Your saved name is not added to requests. What you type may still identify you. Avoid sharing personal details.")
                    Link("Google Gemini API data policies", destination: URL(string: "https://ai.google.dev/gemini-api/terms")!)
                    Text("A keyword scan can miss danger and can also flag everyday phrases. Use Help now whenever you need human support.")
                }
                if let status = status { Section { Text(status).accessibilityIdentifier("settingsStatus") } }
            }
            .navigationTitle("Your space")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear { editedName = userName }
            .sheet(isPresented: $showTerms) { SafetyAgreementView() }
            .confirmationDialog("Delete all saved conversations from this device?", isPresented: $confirmDeletion, titleVisibility: .visible) {
                Button("Delete saved chats", role: .destructive) {
                    do {
                        try LocalChatStore().deleteAll()
                        status = "All saved chats have been deleted from this device."
                    } catch {
                        status = "The saved chats couldn't be deleted. Please try again."
                    }
                }
            }
        }
    }
}
