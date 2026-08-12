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
                Button("Rate Us") {
                    requestReview()
                }
                Button("Privacy Policy") {
                    if let url = URL(string: AppLinks.privacy) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Terms of Use") {
                    if let url = URL(string: AppLinks.terms) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Reset All Data", role: .destructive) {
                    showResetConfirm = true
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
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
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
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
