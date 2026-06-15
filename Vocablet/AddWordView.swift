import SwiftUI
import CoreData
import PhotosUI

// MARK: - Part of Speech options

private let partsOfSpeech = [
    "noun", "verb", "adjective", "adverb",
    "pronoun", "preposition", "conjunction", "interjection",
    "phrase", "idiom"
]

// MARK: - Reorderable fields

enum ReorderableField: String, CaseIterable {
    case definition, example, notes, image
}

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
    @State private var imageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedFolder: CDFolder?
    @State private var selectedMasteryLevel: Int16? = 2

    // Reorderable field order (persisted, shared across cards)
    @AppStorage("addWordFieldOrder") private var fieldOrderRaw: String =
        ReorderableField.allCases.map { $0.rawValue }.joined(separator: ",")
    @State private var fieldOrder: [ReorderableField] = ReorderableField.allCases
    @State private var draggingField: ReorderableField?
    @State private var dragOffset: CGFloat = 0
    @State private var swapAdjustment: CGFloat = 0
    @State private var fieldHeights: [ReorderableField: CGFloat] = [:]

    // AI
    @State private var isAILoading = false
    @State private var aiError: String?
    @State private var showAIError = false
    @State private var aiMeanings: [WordMeaning] = []
    @State private var aiMeaningIndex = 0
    @State private var aiTermFetched = ""

    var isEditing: Bool { word != nil }

    // Design constants
    private let labelColor = Color(hex: "#4D7B9C")
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
                    ForEach(fieldOrder, id: \.self) { field in
                        fieldView(for: field)
                    }
                    folderField
                    masteryLevelField
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
        .onAppear {
            loadExistingData()
            let saved = fieldOrderRaw.split(separator: ",").compactMap { ReorderableField(rawValue: String($0)) }
            let missing = ReorderableField.allCases.filter { !saved.contains($0) }
            fieldOrder = saved + missing
        }
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
                save()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(term.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? Color.lilySecondaryText.opacity(0.4) : Color.lilyAccent)
            }
            .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty)
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
                    Group {
                        if isAILoading {
                            ProgressView().scaleEffect(0.75).tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(term.trimmingCharacters(in: .whitespaces).isEmpty || isAILoading
                                ? Color(hex: "#B8D4E8").opacity(0.4) : Color(hex: "#B8D4E8"))
                    .clipShape(Circle())
                }
                .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty || isAILoading)
            }

        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Reorderable field helpers

    private let fieldSpacing: CGFloat = 18

    @ViewBuilder
    private func fieldView(for field: ReorderableField) -> some View {
        switch field {
        case .definition: reorderable(definitionField, field: field)
        case .example:    reorderable(exampleCard, field: field)
        case .notes:      reorderable(notesField, field: field)
        case .image:      reorderable(imageField, field: field)
        }
    }

    private func dragHandle(_ field: ReorderableField) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.lilySecondaryText)
            .padding(8)
            .contentShape(Rectangle())
            .gesture(dragGesture(for: field))
    }

    private func dragGesture(for field: ReorderableField) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if draggingField != field {
                    draggingField = field
                    swapAdjustment = 0
                }
                dragOffset = value.translation.height - swapAdjustment
                reorderIfNeeded(for: field)
            }
            .onEnded { _ in
                draggingField = nil
                dragOffset = 0
                swapAdjustment = 0
                fieldOrderRaw = fieldOrder.map { $0.rawValue }.joined(separator: ",")
            }
    }

    private func reorderIfNeeded(for field: ReorderableField) {
        guard var idx = fieldOrder.firstIndex(of: field) else { return }

        while dragOffset > 0, idx < fieldOrder.count - 1 {
            let nextHeight = (fieldHeights[fieldOrder[idx + 1]] ?? 80) + fieldSpacing
            guard dragOffset > nextHeight / 2 else { break }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                fieldOrder.swapAt(idx, idx + 1)
            }
            dragOffset -= nextHeight
            swapAdjustment += nextHeight
            idx += 1
        }
        while dragOffset < 0, idx > 0 {
            let prevHeight = (fieldHeights[fieldOrder[idx - 1]] ?? 80) + fieldSpacing
            guard dragOffset < -prevHeight / 2 else { break }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                fieldOrder.swapAt(idx, idx - 1)
            }
            dragOffset += prevHeight
            swapAdjustment -= prevHeight
            idx -= 1
        }
    }

    @ViewBuilder
    private func reorderable<Content: View>(_ content: Content, field: ReorderableField) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { fieldHeights[field] = geo.size.height }
                        .onChange(of: geo.size.height) { _, newHeight in
                            fieldHeights[field] = newHeight
                        }
                }
            )
            .scaleEffect(draggingField == field ? 1.03 : 1)
            .shadow(color: .black.opacity(draggingField == field ? 0.15 : 0), radius: 12, x: 0, y: 6)
            .offset(y: draggingField == field ? dragOffset : 0)
            .zIndex(draggingField == field ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: fieldOrder)
            .animation(.easeOut(duration: 0.15), value: draggingField)
    }

    // MARK: - Image

    private var imageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(loc.imageLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(labelColor)
                Spacer()
                dragHandle(.image)
            }

            if let data = imageData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 180)
                        .cornerRadius(10)
                    Button {
                        imageData = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, Color.black.opacity(0.55))
                    }
                    .padding(6)
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 15))
                        Text(loc.addImage)
                            .font(.system(size: 15))
                        Spacer()
                    }
                    .foregroundStyle(Color.lilySecondaryText)
                }
            }
        }
        .padding(16)
        .background(cardBG)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let item = newItem, let data = try? await item.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
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
                Button("（Blank）") { partOfSpeech = "" }
                ForEach(partsOfSpeech, id: \.self) { pos in
                    Button(pos.capitalized) { partOfSpeech = pos }
                }
            } label: {
                HStack {
                    Text(partOfSpeech.isEmpty ? "（Blank）" : partOfSpeech.capitalized)
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
            HStack {
                Text(loc.englishDefinition)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(labelColor)
                Spacer()
                dragHandle(.definition)
            }
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
            HStack {
                Text(loc.exampleSection)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(labelColor)
                Spacer()
                dragHandle(.example)
            }
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
            HStack {
                Text(loc.notes)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(labelColor)
                Spacer()
                dragHandle(.notes)
            }
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
        case 0: return Color(hex: "#F4A8A8")  // 紅
        case 1: return Color(hex: "#F4C8A0")  // 橘
        case 2: return Color(hex: "#A8D4B0")  // 綠
        case 3: return Color(hex: "#A8C8E8")  // 藍
        default: return Color(hex: "#C4A8E4")  // 紫
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
                let segW = w / 5
                // Align thumb resting positions with the label centers below,
                // which sit at the center of each of the 5 equal-width segments.
                let thumbX = (CGFloat(level) + 0.5) * segW

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
                            let x = min(max(value.location.x, 0), w)
                            let idx = min(max(Int(x / segW), 0), 4)
                            let lvl = Int16(idx)
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

    // MARK: - AI Auto-fill

    private func runAIFill() {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Same word as last fetch and we already have multiple part-of-speech
        // meanings cached — just cycle to the next one locally, no new AI call.
        if trimmed == aiTermFetched, !aiMeanings.isEmpty {
            aiMeaningIndex = (aiMeaningIndex + 1) % aiMeanings.count
            applyMeaning(at: aiMeaningIndex)
            return
        }

        isAILoading = true
        Task {
            do {
                let result = try await AIService.shared.fillWordDetails(for: trimmed)
                await MainActor.run {
                    if !result.kkPhonetic.isEmpty  { pronunciation = result.kkPhonetic }
                    if !result.ipaPhonetic.isEmpty { phoneticIPA   = result.ipaPhonetic }

                    aiMeanings     = orderedByPartOfSpeech(result.meanings)
                    aiMeaningIndex = 0
                    aiTermFetched  = trimmed
                    applyMeaning(at: 0)

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

    /// Sort meanings by their position in the canonical part-of-speech list
    /// (noun, verb, adjective, ...) so the first AI tap always shows the
    /// earliest-ranked part of speech, e.g. noun before verb for "address".
    private func orderedByPartOfSpeech(_ meanings: [WordMeaning]) -> [WordMeaning] {
        meanings.sorted { a, b in
            let ia = partsOfSpeech.firstIndex(of: a.partOfSpeech.lowercased()) ?? partsOfSpeech.count
            let ib = partsOfSpeech.firstIndex(of: b.partOfSpeech.lowercased()) ?? partsOfSpeech.count
            return ia < ib
        }
    }

    /// Apply a single part-of-speech meaning's fields to the form,
    /// replacing (not merging with) any previously-applied meaning.
    private func applyMeaning(at index: Int) {
        guard aiMeanings.indices.contains(index) else { return }
        let m = aiMeanings[index]
        partOfSpeech       = m.partOfSpeech
        chineseTranslation = m.chineseTranslation
        definition         = m.englishDefinition
        exampleSentence    = m.exampleSentence
        exampleTranslation = m.exampleTranslation
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
        imageData          = w.imageData
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
        w.imageData    = imageData
        w.folder       = selectedFolder
        w.masteryLevel = selectedMasteryLevel ?? 2
        w.updatedAt    = Date()

        try? ctx.save()
        dismiss()
    }
}
