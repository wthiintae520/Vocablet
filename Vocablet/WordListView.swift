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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#3A3230"))
            }
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
            Circle()
                .fill(masteryColor)
                .frame(width: 10, height: 10)

            HStack(spacing: 6) {
                Text(word.term ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.lilyText)
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#F4A8C0"))
                }
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
        .padding(.vertical, 0)
    }
}
