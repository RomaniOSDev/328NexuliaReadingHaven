import SwiftUI

struct SynopsisEditorSheet: View {
    enum Mode {
        case create
        case edit(BookSynopsis)

        var navigationTitle: String {
            switch self {
            case .create: return "New Synopsis"
            case .edit: return "Edit Synopsis"
            }
        }
    }

    let mode: Mode
    let onSave: (String, String, String, ChapterStatus) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var bookTitle: String = ""
    @State private var chapter: String = ""
    @State private var synopsisText: String = ""
    @State private var chapterStatus: ChapterStatus = .inProgress
    @State private var showValidationAlert = false

    private var characterCount: Int {
        synopsisText.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var body: some View {
        NavigationStack {
            JournalPage {
                JournalHeading(title: mode.navigationTitle)
                AppTextField(
                    title: "Book title",
                    placeholder: "e.g. The Waves",
                    text: $bookTitle,
                    autocapitalization: .words
                )

                AppTextField(
                    title: "Chapter",
                    placeholder: "Number or name",
                    text: $chapter
                )

                AppSegmentedField(title: "Status", selection: $chapterStatus) {
                    ForEach(ChapterStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }

                AppTextEditorField(
                    title: "Synopsis",
                    placeholder: "Summarize what happens in this chapter…",
                    text: $synopsisText,
                    accessory: "\(characterCount) characters"
                )
            }
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
            .alert("All fields are required.", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func populateIfEditing() {
        if case let .edit(synopsis) = mode {
            bookTitle = synopsis.bookTitle
            chapter = synopsis.chapter
            synopsisText = synopsis.synopsisText
            chapterStatus = synopsis.chapterStatus
        }
    }

    private func attemptSave() {
        if onSave(bookTitle, chapter, synopsisText, chapterStatus) {
            dismiss()
        } else {
            showValidationAlert = true
        }
    }
}
