import SwiftUI
import CoreData

// MARK: - Part of Speech options

private let partsOfSpeech = [
    "noun", "verb", "adjective", "adverb",
    "pronoun", "preposition", "conjunction", "interjection",
    "phrase", "idiom"
]

// MARK: - AddWordView

struct AddWordView: View {
    var word: CDWord?
    var folder: CDFolder?

    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationManager
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDFolder.name)]) private var folders: FetchedResults<CDFolder>
    @AppStorage("defaultBookletID") private var defaultBookletID: String = ""

    // Fields
    @State private var term              = ""
    @State private var pronunciation     = ""   // KK phonetic
    @State private var phoneticIPA       = ""   // IPA phonetic
    @State private var partOfSpeech      = ""
    @State private var chineseTranslation = ""
    @State private var definition        = ""
    @State private var exampleSentence   = ""
    @State private var exampleTranslation = ""
    @State private var notes             = ""
    @State private var selectedFolder: CDFolder?
    @State private var selectedMasteryLevel: Int16? = 2

    // AI
    @State private var isAILoading = false
    @State private var aiError: String?
    @State private var showAIError = false

    var isEditing: Bool { word != nil }

    // Design constants
    private let labelColor = Color(hex: "#4A7B9E")
    private let cardBG     = Color.white
    private let pageBG     = Color(hex: "#F9F9F7")
    private let aiGreen    = Color(hex: "#3A6B8E")

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    wordCard
                    kkPhoneticField
                    ipaPhoneticField
                    translationField
                    partOfSpeechField
                    definitionField
                    exampleCard
                    notesField
                    folderField
                    masteryLevelField
                    saveButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(pageBG.ignoresSafeArea())
        .alert("AI 填寫失敗", isPresented: $showAIError) {
            Button("OK") {}
        } message: {
            Text(aiError ?? "")
        }
        .onAppear { loadExistingData() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 10, height: 10)
                Text(isEditing ? loc.editWordTitle : loc.newWordTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.lilyText)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .medium))
                    Text(loc.cancel).font(.system(size: 14))
                }
                .foregroundStyle(Color.lilySecondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(pageBG)
    }

    // MARK: - Word + AI card

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word input row
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.wordTermLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(labelColor)
                    TextField("", text: $term)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.lilyText)
                        .submitLabel(.done)
                }
                .frame(maxWidth: .infinity)

                // AI Button
                Button {
                    runAIFill()
                } label: {
                    HStack(spacing: 6) {
                        if isAILoading {
                            ProgressView().scaleEffect(0.75).tint(.white)
                            Text(loc.aiFilling)
                                .font(.system(size: 13, weight: .semibold))
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                            Text(loc.aiAutoFill)
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(term.trimmingCharacters(in: .whitespaces).isEmpty || isAILoading
                                ? aiGreen.opacity(0.4) : aiGreen)
                    .cornerRadius(10)
                }
                .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty || isAILoading)
            }

        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - KK Phonetic

    private var kkPhoneticField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.kkPhoneticLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            TextField("", text: $pronunciation)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(Color.lilyText)
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - IPA Phonetic

    private var ipaPhoneticField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.ipaPhoneticLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            TextField("", text: $phoneticIPA)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(Color.lilyText)
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Part of Speech

    private var partOfSpeechField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.partOfSpeech)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            Menu {
                ForEach(partsOfSpeech, id: \.self) { pos in
                    Button(pos.capitalized) { partOfSpeech = pos }
                }
                Button("clear") { partOfSpeech = "" }
            } label: {
                HStack {
                    Text(partOfSpeech.isEmpty ? "Noun" : partOfSpeech.capitalized)
                        .font(.system(size: 15))
                        .foregroundStyle(partOfSpeech.isEmpty ? Color.lilySecondaryText : Color.lilyText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lilySecondaryText)
                }
            }
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Chinese Translation

    private var translationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.chineseTranslation)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            TextField("", text: $chineseTranslation)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - English Definition

    private var definitionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.englishDefinition)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            TextEditor(text: $definition)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Example sentence card (grouped)

    private var exampleCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.exampleSection)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            TextField("", text: $exampleSentence)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
            Divider()
            Text(loc.exampleTranslation)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
                .padding(.top, 4)
            TextField("", text: $exampleTranslation)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Notes

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.notes)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            TextEditor(text: $notes)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Folder

    private var folderField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.folderLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)
            Menu {
                ForEach(folders) { f in
                    Button(f.name ?? "") { selectedFolder = f }
                }
            } label: {
                HStack {
                    Text(selectedFolder?.name ?? "")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.lilyText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lilySecondaryText)
                }
            }
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Mastery Level field

    private func masteryChipColor(_ level: Int16) -> Color {
        switch level {
        case 0: return Color(hex: "#F4A8C0")
        case 1: return Color(hex: "#F4D4A0")
        case 2, 3: return Color(hex: "#A8C8E8")
        default: return Color(hex: "#7EC8A4")
        }
    }

    private var masteryLevelField: some View {
        let level = Int(selectedMasteryLevel ?? 2)

        return VStack(alignment: .leading, spacing: 16) {
            Text(loc.masteryLevelLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(labelColor)

            GeometryReader { geo in
                let w = geo.size.width
                let step = w / 4
                let thumbX = CGFloat(level) * step

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(width: 40, height: 30)
                        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
                        .offset(x: thumbX - 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let ratio = min(max(value.location.x / w, 0), 1)
                            let lvl = Int16((ratio * 4).rounded())
                            if selectedMasteryLevel != lvl {
                                withAnimation(.easeOut(duration: 0.12)) {
                                    selectedMasteryLevel = lvl
                                }
                            }
                        }
                )
            }
            .frame(height: 30)

            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { lvl in
                    let lv = Int16(lvl)
                    let isSelected = level == lvl
                    VStack(spacing: 8) {
                        Circle()
                            .fill(masteryChipColor(lv))
                            .frame(width: isSelected ? 7 : 5, height: isSelected ? 7 : 5)
                        Text("\(lvl * 25)%")
                            .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? Color.lilyText : Color.lilySecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) { selectedMasteryLevel = lv }
                    }
                }
            }
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text(loc.saveWord)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                term.trimmingCharacters(in: .whitespaces).isEmpty ||
                definition.trimmingCharacters(in: .whitespaces).isEmpty
                ? aiGreen.opacity(0.4) : aiGreen
            )
            .cornerRadius(14)
        }
        .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty ||
                  definition.trimmingCharacters(in: .whitespaces).isEmpty)
        .padding(.bottom, 8)
    }

    // MARK: - AI Auto-fill

    private func runAIFill() {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isAILoading = true
        Task {
            do {
                let result = try await AIService.shared.fillWordDetails(for: trimmed)
                await MainActor.run {
                    if !result.kkPhonetic.isEmpty         { pronunciation      = result.kkPhonetic }
                    if !result.ipaPhonetic.isEmpty        { phoneticIPA        = result.ipaPhonetic }
                    if !result.partOfSpeech.isEmpty       { partOfSpeech       = result.partOfSpeech }
                    if !result.chineseTranslation.isEmpty { chineseTranslation = result.chineseTranslation }
                    if !result.englishDefinition.isEmpty  { definition         = result.englishDefinition }
                    if !result.exampleSentence.isEmpty    { exampleSentence    = result.exampleSentence }
                    if !result.exampleTranslation.isEmpty { exampleTranslation = result.exampleTranslation }
                    isAILoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = error.localizedDescription
                    showAIError = true
                    isAILoading = false
                }
            }
        }
    }

    // MARK: - Helpers

    private var defaultFolder: CDFolder? {
        folders.first { $0.id?.uuidString == defaultBookletID }
    }

    private func loadExistingData() {
        guard let w = word else {
            selectedFolder = folder ?? defaultFolder
            return
        }
        term               = w.term               ?? ""
        definition         = w.definition         ?? ""
        pronunciation      = w.pronunciation      ?? ""
        phoneticIPA        = w.phoneticIPA        ?? ""
        partOfSpeech       = w.partOfSpeech       ?? ""
        chineseTranslation = w.chineseTranslation ?? ""
        exampleSentence    = w.examples           ?? ""
        exampleTranslation = w.exampleTranslation ?? ""
        notes              = w.notes              ?? ""
        selectedMasteryLevel = w.masteryLevel
        selectedFolder     = w.folder
    }

    private func save() {
        let w = word ?? CDWord(context: ctx)
        if word == nil { w.id = UUID(); w.createdAt = Date() }
        w.term               = term.trimmingCharacters(in: .whitespaces)
        w.definition         = definition.trimmingCharacters(in: .whitespaces)
        w.pronunciation      = pronunciation.trimmingCharacters(in: .whitespaces)
        w.phoneticIPA        = phoneticIPA.trimmingCharacters(in: .whitespaces)
        w.partOfSpeech       = partOfSpeech
        w.chineseTranslation = chineseTranslation.trimmingCharacters(in: .whitespaces)
        w.examples           = exampleSentence.trimmingCharacters(in: .whitespaces)
        w.exampleTranslation = exampleTranslation.trimmingCharacters(in: .whitespaces)
        w.notes              = notes.trimmingCharacters(in: .whitespaces)
        w.folder             = selectedFolder
        w.masteryLevel = selectedMasteryLevel ?? 2

        try? ctx.save()
        dismiss()
    }
}
