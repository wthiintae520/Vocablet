import SwiftUI
import CoreData

struct FolderView: View {
    @ObservedObject var folder: CDFolder
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager
    @State private var showAddWord = false
    @State private var showQuiz = false

    var words: [CDWord] {
        (folder.words?.allObjects as? [CDWord] ?? [])
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        List {
            if !words.isEmpty {
                Section {
                    Button { showQuiz = true } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(Color(hex: folder.colorHex ?? "#7EC8A4"))
                            Text(loc.startQuiz)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(hex: folder.colorHex ?? "#7EC8A4"))
                            Spacer()
                            Text("\(words.count) \(loc.wordsCount)")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color.lilySecondaryText)
                        }
                    }
                }
            }

            Section {
                ForEach(words) { word in
                    NavigationLink(destination: WordDetailView(word: word)) {
                        WordRow(word: word)
                    }
                }
                .onDelete(perform: deleteWords)
            } header: {
                Text(loc.wordList)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.lilySecondaryText)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.lilyBackground)
        .navigationTitle(folder.name ?? loc.unnamed)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddWord = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: folder.colorHex ?? "#7EC8A4"))
                }
            }
        }
        .sheet(isPresented: $showAddWord) { AddWordView(folder: folder) }
        .sheet(isPresented: $showQuiz)   { QuizView(words: words) }
    }

    private func deleteWords(at offsets: IndexSet) {
        withAnimation {
            offsets.map { words[$0] }.forEach(ctx.delete)
            try? ctx.save()
        }
    }
}
