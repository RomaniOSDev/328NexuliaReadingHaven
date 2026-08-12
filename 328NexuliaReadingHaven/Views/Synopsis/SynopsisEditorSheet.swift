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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    fieldLabel("Book title")
                    TextField("Book title", text: $bookTitle)
                        .appFieldStyle()
                        .textInputAutocapitalization(.words)

                    fieldLabel("Chapter")
                    TextField("Chapter", text: $chapter)
                        .appFieldStyle()

                    fieldLabel("Status")
                    Picker("Status", selection: $chapterStatus) {
                        ForEach(ChapterStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color("AppSurface").opacity(0.85))
                    )

                    HStack {
                        fieldLabel("Synopsis")
                        Spacer()
                        Text("\(characterCount) characters")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    TextEditor(text: $synopsisText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .appFieldStyle()
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
            .alert("All fields are required.", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
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
