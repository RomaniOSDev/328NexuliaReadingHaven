import SwiftUI

struct DraftEditorSheet: View {
    enum Mode {
        case create
        case edit(SynopsisDraft)

        var navigationTitle: String {
            switch self {
            case .create: return "New Draft"
            case .edit: return "Edit Draft"
            }
        }

        var existingDraft: SynopsisDraft? {
            if case let .edit(draft) = self { return draft }
            return nil
        }
    }

    let mode: Mode
    let onSave: (String, String, UUID?) -> Bool
    var onPromote: ((SynopsisDraft) -> Void)?

    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var bookTitle: String = ""
    @State private var draftText: String = ""
    @State private var linkedBookId: UUID?
    @State private var showValidationAlert = false
    @State private var showPromoteChapterPrompt = false
    @State private var promoteChapter = "1"

    private var characterCount: Int {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var meetsMinimum: Bool {
        characterCount >= SynopsisDraft.minimumCharacterCount
    }

    private var progress: Double {
        min(1, Double(characterCount) / Double(SynopsisDraft.minimumCharacterCount))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    fieldLabel("Book title")
                    TextField("Book title", text: $bookTitle)
                        .appFieldStyle()
                        .textInputAutocapitalization(.words)

                    if !store.synopses.isEmpty {
                        fieldLabel("Link to synopsis")
                        Picker("Link to synopsis", selection: $linkedBookId) {
                            Text("None").tag(UUID?.none)
                            ForEach(store.synopses.sorted(by: { $0.bookTitle < $1.bookTitle })) { synopsis in
                                Text(synopsis.bookTitle).tag(Optional(synopsis.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color("AppAccent"))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color("AppSurface").opacity(0.85))
                        )
                        .onChange(of: linkedBookId) { newValue in
                            if let id = newValue, let synopsis = store.synopsis(for: id), bookTitle.isEmpty {
                                bookTitle = synopsis.bookTitle
                            }
                        }
                    }

                    HStack {
                        fieldLabel("Draft")
                        Spacer()
                        Text("\(characterCount) / \(SynopsisDraft.minimumCharacterCount) min")
                            .font(.caption)
                            .foregroundStyle(meetsMinimum ? Color("AppAccent") : Color("AppTextSecondary"))
                    }

                    TextEditor(text: $draftText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .appFieldStyle()

                    ProgressView(value: progress)
                        .tint(meetsMinimum ? Color("AppAccent") : Color("AppPrimary"))

                    Text(meetsMinimum ? "Ready to save." : "Keep writing to reach the minimum length.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))

                    if mode.existingDraft != nil {
                        Button("Promote to synopsis") {
                            promoteChapter = "1"
                            showPromoteChapterPrompt = true
                        }
                        .buttonStyle(PrimaryGradientButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                }
                .padding(16)
            }
            .appScreenBackground()
            .navigationTitle(mode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .onAppear(perform: populateIfEditing)
            .alert("Enter a title and at least \(SynopsisDraft.minimumCharacterCount) characters.", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert("Chapter number", isPresented: $showPromoteChapterPrompt) {
                TextField("Chapter", text: $promoteChapter)
                Button("Promote") { performPromote() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("A synopsis will be created from this draft.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("AppTextSecondary"))
    }

    private func populateIfEditing() {
        if case let .edit(draft) = mode {
            bookTitle = draft.bookTitle
            draftText = draft.draftText
            linkedBookId = draft.bookId
        }
    }

    private func attemptSave() {
        if onSave(bookTitle, draftText, linkedBookId) {
            dismiss()
        } else {
            showValidationAlert = true
        }
    }

    private func performPromote() {
        guard var draft = mode.existingDraft else { return }
        draft.bookTitle = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? draft.bookTitle
            : bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.draftText = draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? draft.draftText
            : draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let chapter = promoteChapter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "1"
            : promoteChapter.trimmingCharacters(in: .whitespacesAndNewlines)
        if let created = store.promoteDraftToSynopsis(draft, chapter: chapter) {
            onPromote?(draft)
            _ = created
            dismiss()
        } else {
            showValidationAlert = true
        }
    }
}
