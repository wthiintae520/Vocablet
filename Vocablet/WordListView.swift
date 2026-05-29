import SwiftUI
import CoreData

struct WordListView: View {
    let title: String
    let predicate: NSPredicate?
    @EnvironmentObject var loc: LocalizationManager
    @State private var showAddWord = false

    var body: some View {
        _WordListContent(title: title, predicate: predicate, showAddWord: $showAddWord)
            .sheet(isPresented: $showAddWord) { AddWordView(folder: nil) }
    }
}

private struct _WordListContent: View {
    let title: String
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager
    @FetchRequest var words: FetchedResults<CDWord>
    @Binding var showAddWord: Bool

    init(title: String, predicate: NSPredicate?, showAddWord: Binding<Bool>) {
        self.title = title
        _words = FetchRequest<CDWord>(
            sortDescriptors: [SortDescriptor(\CDWord.createdAt, order: .reverse)],
            predicate: predicate, animation: .default)
        _showAddWord = showAddWord
    }

    var body: some View {
        List {
            ForEach(words) { word in
                NavigationLink(destination: WordDetailView(word: word)) { WordRow(word: word) }
            }
            .onDelete(perform: deleteWords)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.lilyBackground)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddWord = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.lilyAccent)
                }
            }
        }
        .overlay {
            if words.isEmpty {
                ContentUnavailableView(loc.emptyWords, systemImage: "text.book.closed",
                                       description: Text(loc.emptyWordsHint))
            }
        }
    }

    private func deleteWords(at offsets: IndexSet) {
        withAnimation {
            offsets.map { words[$0] }.forEach(ctx.delete)
            try? ctx.save()
        }
    }
}

struct WordRow: View {
    @ObservedObject var word: CDWord
    @EnvironmentObject var loc: LocalizationManager

    var masteryColor: Color {
        switch word.masteryLevel {
        case 0: return Color(hex: "#F4A8C0")
        case 1: return Color(hex: "#F4D4A0")
        case 2, 3: return Color(hex: "#A8C8E8")
        default: return Color(hex: "#7EC8A4")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(loc.masteryText(word.masteryLevel))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(masteryColor)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(word.term ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.lilyText)
                    if word.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#F4A8C0"))
                    }
                }
                Text(word.definition ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.lilySecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            if let tags = word.tags as? Set<CDTag>, let first = tags.first {
                Text(first.name ?? "")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.lilyAccent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.lilyAccent.opacity(0.12))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 2)
    }
}
