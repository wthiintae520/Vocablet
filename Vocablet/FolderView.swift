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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(words.enumerated()), id: \.element.objectID) { index, word in
                    NavigationLink(destination: WordDetailView(word: word)) {
                        HStack {
                            WordRow(word: word)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.lilySecondaryText.opacity(0.4))
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
                    if index < words.count - 1 {
                        Divider()
                            .padding(.leading, 38)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
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
}
