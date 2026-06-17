import SwiftUI
import CoreData

struct FolderView: View {
    @ObservedObject var folder: CDFolder
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager
    @State private var showAddWord = false
    @AppStorage("folderSortByName") private var sortByName = false

    var words: [CDWord] {
        let raw = folder.words?.allObjects as? [CDWord] ?? []
        if sortByName {
            return raw.sorted { ($0.term ?? "").localizedCompare($1.term ?? "") == .orderedAscending }
        } else {
            return raw.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(words) { word in
                    NavigationLink(destination: WordDetailView(word: word)) {
                        WordRow(word: word)
                    }
                    .contextMenu {
                        Button {
                            withAnimation { sortByName = true }
                        } label: {
                            Label(loc.sortByNameAZ, systemImage: "textformat.abc")
                        }
                        Button {
                            withAnimation { sortByName = false }
                        } label: {
                            Label(loc.sortByDate, systemImage: "clock")
                        }
                        Divider()
                        Button(role: .destructive) {
                            ctx.delete(word)
                            try? ctx.save()
                        } label: {
                            Label(loc.deleteBooklet, systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteWords)
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color.lilyBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(folder.name ?? loc.unnamed)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#3A3230"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddWord = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: "#B8D4E8"))
                }
            }
        }
        .sheet(isPresented: $showAddWord) { AddWordView(folder: folder) }
    }

    private func deleteWords(at offsets: IndexSet) {
        withAnimation {
            offsets.map { words[$0] }.forEach(ctx.delete)
            try? ctx.save()
        }
    }
}
