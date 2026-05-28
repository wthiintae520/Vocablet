import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var ctx
    @State private var query = ""
    @State private var filterMode: FilterMode = .all

    @FetchRequest(sortDescriptors: [SortDescriptor(\CDTag.name)]) private var allTags: FetchedResults<CDTag>

    enum FilterMode: String, CaseIterable {
        case all = "全部"
        case term = "單字"
        case definition = "定義"
        case tag = "標籤"
    }

    var predicate: NSPredicate? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        switch filterMode {
        case .all:
            return NSPredicate(format: "term CONTAINS[cd] %@ OR definition CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@",
                               trimmed, trimmed, trimmed)
        case .term:
            return NSPredicate(format: "term CONTAINS[cd] %@", trimmed)
        case .definition:
            return NSPredicate(format: "definition CONTAINS[cd] %@", trimmed)
        case .tag:
            return NSPredicate(format: "ANY tags.name CONTAINS[cd] %@", trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("篩選", selection: $filterMode) {
                    ForEach(FilterMode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.lilyBackground)

                if query.isEmpty && filterMode == .tag {
                    tagBrowserSection
                } else {
                    SearchResultsList(predicate: predicate)
                }
            }
            .background(Color.lilyBackground)
            .navigationTitle("搜尋")
            .searchable(text: $query, prompt: "搜尋單字、定義或標籤")
        }
    }

    private var tagBrowserSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("所有標籤")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.lilySecondaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                FlowLayout(spacing: 8) {
                    ForEach(allTags) { tag in
                        Button {
                            query = tag.name ?? ""
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 10))
                                Text(tag.name ?? "")
                                    .font(.system(size: 14, design: .rounded))
                                Text("\(tag.words?.count ?? 0)")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(Color.lilySecondaryText)
                            }
                            .foregroundStyle(Color.lilyAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.lilyAccent.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

private struct SearchResultsList: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest var words: FetchedResults<CDWord>

    init(predicate: NSPredicate?) {
        _words = FetchRequest<CDWord>(
            sortDescriptors: [SortDescriptor(\CDWord.term)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        List {
            ForEach(words) { word in
                NavigationLink(destination: WordDetailView(word: word)) {
                    WordRow(word: word)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay {
            if words.isEmpty {
                ContentUnavailableView.search
            }
        }
    }
}

#Preview {
    SearchView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
