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
    @State private var tagInput          = ""
    @State private var tagList: [String] = []
    @State private var selectedFolder: CDFolder?
    @State private var isMastered        = false

    // AI
    @State private var isAILoading = false
    @State private var aiError: String?
    @State private var showAIError = false

    var isEditing: Bool { word != nil }

    // Design constants
    private let labelColor = Color(hex: "#4A7B62")
    private let cardBG     = Color.white
    private let pageBG     = Color(hex: "#F5F5F0")
    private let aiGreen    = Color(hex: "#3A6651")

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    wordCard
                    translationField
                    definitionField
                    exampleCard
                    notesField
                    folderField
                    tagsField
                    actionRow
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
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color(hex: "#F4D4A0"))
                    .font(.system(size: 16))
                Text(isEditing ? loc.editWordTitle : loc.newWordTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.lilyText)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .medium))
                    Text(loc.cancel).font(.system(size: 14, design: .rounded))
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
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(labelColor)
                    TextField("例如：serendipity", text: $term)
                        .font(.system(size: 16, design: .rounded))
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
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                            Text(loc.aiAutoFill)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
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

            Divider().background(Color.lilyBorder)

            // KK + IPA + Part of Speech
            HStack(spacing: 12) {
                // KK Phonetic
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.kkPhoneticLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(labelColor)
                    TextField("/ˋwɔtɚ/", text: $pronunciation)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.lilySecondaryText)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.lilyBorder).frame(width: 1, height: 44)

                // IPA Phonetic
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.ipaPhoneticLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(labelColor)
                    TextField("/ˈwɔːtər/", text: $phoneticIPA)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.lilySecondaryText)
                }
                .frame(maxWidth: .infinity)
            }

            Divider().background(Color.lilyBorder)

            // Part of Speech
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.partOfSpeech)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(labelColor)
                Menu {
                    ForEach(partsOfSpeech, id: \.self) { pos in
                        Button(pos.capitalized) { partOfSpeech = pos }
                    }
                    Button("clear") { partOfSpeech = "" }
                } label: {
                    HStack {
                        Text(partOfSpeech.isEmpty ? "Noun" : partOfSpeech.capitalized)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(partOfSpeech.isEmpty ? Color.lilySecondaryText : Color.lilyText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.lilySecondaryText)
                    }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.chineseTranslation)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
            TextField("例如：不期而遇的美好、緣分", text: $chineseTranslation)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.lilyText)
                .padding(12)
                .background(cardBG)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - English Definition

    private var definitionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("英文詳細釋義 (Definition)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
            ZStack(alignment: .topLeading) {
                if definition.isEmpty {
                    Text("例如：The occurrence of events by chance in a happy or beneficial way.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText.opacity(0.6))
                        .padding(.top, 8).padding(.leading, 4)
                }
                TextEditor(text: $definition)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            }
            .padding(12)
            .background(cardBG)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Example sentence card (grouped)

    private var exampleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("英文例句 (Sentence Example)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                // English example
                VStack(alignment: .leading, spacing: 6) {
                    TextField("例如：We found the charming little café by pure serendipity.", text: $exampleSentence)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.lilyText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().padding(.horizontal, 14)

                // Chinese translation
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.exampleTranslation)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(labelColor)
                    TextField("例如：我們純粹碰巧發現了那家迷人的半山咖啡館。", text: $exampleTranslation)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(cardBG)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#D8E8DF"), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Notes

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 \(loc.myNotes)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("在此記錄自己的記憶巧思、字根聯想，或是同義反義字…")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText.opacity(0.6))
                        .padding(.top, 8).padding(.leading, 4)
                }
                TextEditor(text: $notes)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            }
            .padding(12)
            .background(cardBG)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Folder

    private var folderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.folderLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
            Menu {
                Button(loc.noCategory) { selectedFolder = nil }
                ForEach(folders) { f in
                    Button {
                        selectedFolder = f
                    } label: {
                        Label(f.name ?? "", systemImage: f.icon ?? "folder.fill")
                    }
                }
            } label: {
                HStack {
                    if let f = selectedFolder {
                        Image(systemName: f.icon ?? "folder.fill")
                            .foregroundStyle(Color(hex: f.colorHex ?? "#7EC8A4"))
                        Text(f.name ?? "")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(Color.lilyText)
                    } else {
                        Text(loc.noCategory)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(Color.lilySecondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lilySecondaryText)
                }
                .padding(12)
                .background(cardBG)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
        }
    }

    // MARK: - Tags

    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.tags)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField(loc.tagInputHint, text: $tagInput)
                        .font(.system(size: 14, design: .rounded))
                        .onSubmit { addTag() }
                    if !tagInput.isEmpty {
                        Button(loc.add) { addTag() }
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(labelColor)
                    }
                }
                if !tagList.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(tagList, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(Color.lilyAccent)
                                Button {
                                    tagList.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.lilySecondaryText)
                                }
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.lilyAccent.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(12)
            .background(cardBG)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Action row (Mastered)

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                isMastered.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isMastered ? "checkmark.seal.fill" : "checkmark.seal")
                        .foregroundStyle(isMastered ? Color.lilyAccent : Color.lilySecondaryText)
                    Text(loc.markAsMastered)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(isMastered ? Color.lilyText : Color.lilySecondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(isMastered ? Color.lilyAccent.opacity(0.1) : cardBG)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
            }
        }
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text(loc.saveWord)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
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

    private func addTag() {
        let t = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty, !tagList.contains(t) { tagList.append(t) }
        tagInput = ""
    }

    private func loadExistingData() {
        guard let w = word else { selectedFolder = folder; return }
        term               = w.term               ?? ""
        definition         = w.definition         ?? ""
        pronunciation      = w.pronunciation      ?? ""
        phoneticIPA        = w.phoneticIPA        ?? ""
        partOfSpeech       = w.partOfSpeech       ?? ""
        chineseTranslation = w.chineseTranslation ?? ""
        exampleSentence    = w.examples           ?? ""
        exampleTranslation = w.exampleTranslation ?? ""
        notes              = w.notes              ?? ""
        isMastered         = w.masteryLevel >= 4
        selectedFolder     = w.folder
        tagList            = (w.tags as? Set<CDTag>)?.compactMap { $0.name } ?? []
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
        if isMastered { w.masteryLevel = 4 }

        // Tags
        if let oldTags = w.tags as? Set<CDTag> { oldTags.forEach { w.removeFromTags($0) } }
        for tagName in tagList {
            let req = CDTag.fetchRequest()
            req.predicate = NSPredicate(format: "name == %@", tagName)
            let existing = (try? ctx.fetch(req))?.first
            let tag = existing ?? CDTag(context: ctx)
            if existing == nil { tag.id = UUID(); tag.name = tagName }
            w.addToTags(tag)
        }
        try? ctx.save()
        dismiss()
    }
}
