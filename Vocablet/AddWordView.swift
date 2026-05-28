import SwiftUI
import CoreData

struct AddWordView: View {
    var word: CDWord?
    var folder: CDFolder?

    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationManager
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDFolder.name)]) private var folders: FetchedResults<CDFolder>

    @State private var term = ""
    @State private var definition = ""
    @State private var pronunciation = ""
    @State private var examples = ""
    @State private var notes = ""
    @State private var tagInput = ""
    @State private var tagList: [String] = []
    @State private var selectedFolder: CDFolder?
    @State private var isFavorite = false

    var isEditing: Bool { word != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(loc.wordTermLabel) {
                    TextField("e.g. serendipity", text: $term)
                        .font(.system(size: 16, design: .rounded))
                    TextField(loc.phoneticHint, text: $pronunciation)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                Section(loc.defLabel) {
                    TextEditor(text: $definition)
                        .font(.system(size: 15, design: .rounded))
                        .frame(minHeight: 80)
                }

                Section(loc.examples) {
                    TextEditor(text: $examples)
                        .font(.system(size: 15, design: .rounded))
                        .frame(minHeight: 60)
                }

                Section(loc.notes) {
                    TextEditor(text: $notes)
                        .font(.system(size: 15, design: .rounded))
                        .frame(minHeight: 60)
                }

                Section(loc.tags) {
                    HStack {
                        TextField(loc.tagInputHint, text: $tagInput)
                            .font(.system(size: 15, design: .rounded))
                            .onSubmit { addTag() }
                        if !tagInput.isEmpty {
                            Button(loc.add) { addTag() }
                                .foregroundStyle(Color.lilyAccent)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    if !tagList.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(tagList, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(Color.lilyAccent)
                                    Button {
                                        tagList.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.lilySecondaryText)
                                    }
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.lilyAccent.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(loc.folderLabel) {
                    Picker(loc.selectFolder, selection: $selectedFolder) {
                        Text(loc.noCategory).tag(Optional<CDFolder>.none)
                        ForEach(folders) { f in
                            HStack {
                                Image(systemName: f.icon ?? "folder.fill")
                                Text(f.name ?? "")
                            }.tag(Optional(f))
                        }
                    }
                }

                Section {
                    Toggle(isOn: $isFavorite) {
                        Label(loc.addToFav, systemImage: "heart")
                    }
                    .tint(Color(hex: "#F4A8C0"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationTitle(isEditing ? loc.editWordTitle : loc.addWordTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.cancel) { dismiss() }.foregroundStyle(Color.lilySecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? loc.save : loc.done) { save() }
                        .foregroundStyle(Color.lilyAccent).fontWeight(.semibold)
                        .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  definition.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExistingData() }
        }
    }

    private func addTag() {
        let t = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty, !tagList.contains(t) { tagList.append(t) }
        tagInput = ""
    }

    private func loadExistingData() {
        guard let w = word else { selectedFolder = folder; return }
        term = w.term ?? ""; definition = w.definition ?? ""
        pronunciation = w.pronunciation ?? ""; examples = w.examples ?? ""
        notes = w.notes ?? ""; isFavorite = w.isFavorite
        selectedFolder = w.folder
        tagList = (w.tags as? Set<CDTag>)?.compactMap { $0.name } ?? []
    }

    private func save() {
        let w = word ?? CDWord(context: ctx)
        if word == nil { w.id = UUID(); w.createdAt = Date() }
        w.term = term.trimmingCharacters(in: .whitespaces)
        w.definition = definition.trimmingCharacters(in: .whitespaces)
        w.pronunciation = pronunciation.trimmingCharacters(in: .whitespaces)
        w.examples = examples.trimmingCharacters(in: .whitespaces)
        w.notes = notes.trimmingCharacters(in: .whitespaces)
        w.isFavorite = isFavorite; w.folder = selectedFolder
        if let oldTags = w.tags as? Set<CDTag> { oldTags.forEach { w.removeFromTags($0) } }
        for tagName in tagList {
            let req = CDTag.fetchRequest(); req.predicate = NSPredicate(format: "name == %@", tagName)
            let existing = (try? ctx.fetch(req))?.first
            let tag = existing ?? CDTag(context: ctx)
            if existing == nil { tag.id = UUID(); tag.name = tagName }
            w.addToTags(tag)
        }
        try? ctx.save(); dismiss()
    }
}
