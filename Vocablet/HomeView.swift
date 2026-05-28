import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDFolder.createdAt)], animation: .default)
    private var folders: FetchedResults<CDFolder>
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDWord.createdAt, order: .reverse)])
    private var allWords: FetchedResults<CDWord>

    @State private var showAddFolder = false
    @State private var showAddWord = false

    var favoriteCount: Int { allWords.filter { $0.isFavorite }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: WordListView(title: "所有單字", predicate: nil)) {
                        QuickAccessRow(icon: "tray.full.fill", color: .lilyAccent,
                                       label: "所有單字", count: allWords.count)
                    }
                    NavigationLink(destination: WordListView(title: "我的最愛",
                                                             predicate: NSPredicate(format: "isFavorite == true"))) {
                        QuickAccessRow(icon: "heart.fill", color: Color(hex: "#F4A8C0"),
                                       label: "我的最愛", count: favoriteCount)
                    }
                }

                Section {
                    ForEach(folders) { folder in
                        NavigationLink(destination: FolderView(folder: folder)) {
                            FolderRow(folder: folder)
                        }
                    }
                    .onDelete(perform: deleteFolders)
                } header: {
                    Text("資料夾")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationTitle("Vocablet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showAddFolder = true } label: {
                            Image(systemName: "folder.badge.plus")
                                .foregroundStyle(Color.lilyAccent)
                        }
                        Button { showAddWord = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.lilyAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFolder) { AddFolderView() }
            .sheet(isPresented: $showAddWord) { AddWordView(folder: nil) }
        }
    }

    private func deleteFolders(at offsets: IndexSet) {
        withAnimation {
            offsets.map { folders[$0] }.forEach(ctx.delete)
            try? ctx.save()
        }
    }
}

struct QuickAccessRow: View {
    let icon: String
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
            Text(label)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color.lilyText)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.lilySecondaryText)
        }
        .padding(.vertical, 2)
    }
}

struct FolderRow: View {
    @ObservedObject var folder: CDFolder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: folder.icon ?? "folder.fill")
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color(hex: folder.colorHex ?? "#7EC8A4"))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name ?? "未命名")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                Text("\(folder.words?.count ?? 0) 個單字")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.lilySecondaryText)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
