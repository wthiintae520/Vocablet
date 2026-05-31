import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDFolder.createdAt)], animation: .default)
    private var folders: FetchedResults<CDFolder>
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDWord.createdAt, order: .reverse)])
    private var allWords: FetchedResults<CDWord>

    @State private var showAddFolder = false
    @State private var showAddWord = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: WordListView(title: loc.allCards, predicate: nil)) {
                        QuickAccessRow(icon: "books.vertical.fill", color: .lilyAccent,
                                       label: loc.allCards, count: allWords.count)
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
                    Text(loc.booklets)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .contentMargins(.top, 4, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.appName)
                        .font(.custom("PlusJakartaSans-Bold", size: 13))
                        .kerning(2.5)
                        .foregroundStyle(Color(hex: "#5C5552"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showAddFolder = true } label: {
                            Image(systemName: "note.text.badge.plus").foregroundStyle(Color.lilyAccent)
                        }
                        Button { showAddWord = true } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Color.lilyAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFolder) { AddFolderView() }
            .sheet(isPresented: $showAddWord) { AddWordView(folder: nil) }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    NavigationLink(destination: SearchView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.lilySecondaryText)
                            Text(loc.searchTitle)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.lilySecondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.lilyBorder.opacity(0.6))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.lilySecondaryText)
                    }
                    .padding(.leading, 12)
                }
            }
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
    let icon: String; let color: Color; let label: String; let count: Int
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
                .background(color).cornerRadius(6)
            Text(label)
                .font(.system(size: 13)).foregroundStyle(Color.lilyText)
            Spacer()
            Text("\(count)")
                .font(.system(size: 13)).foregroundStyle(Color.lilySecondaryText)
        }
        .padding(.vertical, 0)
    }
}

struct FolderRow: View {
    @ObservedObject var folder: CDFolder
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: folder.icon ?? "folder.fill")
                .foregroundStyle(.white)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
                .background(Color(hex: folder.colorHex ?? "#B8D4E8")).cornerRadius(6)
            Text(folder.name ?? "")
                .font(.system(size: 13)).foregroundStyle(Color.lilyText)
            Spacer()
            Text("\(folder.words?.count ?? 0)")
                .font(.system(size: 13)).foregroundStyle(Color.lilySecondaryText)
        }
        .padding(.vertical, 0)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocalizationManager.shared)
}
