import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var showReviewUnavailable = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    settingsRow("Rate Us", icon: "star") { requestReview() }
                    settingsRow("Privacy Policy", icon: "hand.raised") { open(AppLinks.privacy) }
                    settingsRow("Terms of Use", icon: "doc.plaintext") { open(AppLinks.terms) }
                } header: {
                    Text("About")
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Journal data")
                }
                .listRowBackground(AppPalette.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .appScreenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppPalette.accent)
                }
            }
            .confirmationDialog(
                "Reset all synopses and drafts?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset All Data", role: .destructive) {
                    store.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Unable to show review prompt", isPresented: $showReviewUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again later from a device build.")
            }
        }
        .appCompactSheetChrome()
    }

    private func settingsRow(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(AppPalette.ink)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(AppPalette.accent)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func open(_ address: String) {
        if let url = URL(string: address) {
            UIApplication.shared.open(url)
        }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            showReviewUnavailable = true
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}
