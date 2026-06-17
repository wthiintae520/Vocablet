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
    @State private var folderToRename: CDFolder? = nil
    @State private var newFolderName = ""
    @AppStorage("homeSortByName") private var sortByName = false
    @AppStorage("defaultBookletID") private var defaultBookletID: String = ""

    var defaultFolder: CDFolder? {
        folders.first { $0.id?.uuidString == defaultBookletID }
    }

    var sortedFolders: [CDFolder] {
        let pinned  = folders.filter { $0.id?.uuidString == defaultBookletID }
        let others  = folders.filter { $0.id?.uuidString != defaultBookletID }
        let sorted  = sortByName
            ? others.sorted { ($0.name ?? "").localizedCompare($1.name ?? "") == .orderedAscending }
            : others
        return pinned + sorted
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            List {
                Section {
                    NavigationLink(destination: WordListView(title: loc.allCards, predicate: nil)) {
                        QuickAccessRow(icon: "books.vertical.fill", color: .lilyAccent,
                                       label: loc.allCards, count: allWords.count)
                    }
                }

                Section {
                    ForEach(sortedFolders) { folder in
                        let isDefault = folder.id?.uuidString == defaultBookletID
                        NavigationLink(destination: FolderView(folder: folder)) {
                            FolderRow(folder: folder)
                        }
                        .contextMenu {
                            Button {
                                newFolderName = folder.name ?? ""
                                folderToRename = folder
                            } label: {
                                Label(loc.renameBooklet, systemImage: "pencil")
                            }
                            Divider()
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
                            if !isDefault {
                                Divider()
                                Button(role: .destructive) {
                                    ctx.delete(folder)
                                    try? ctx.save()
                                } label: {
                                    Label(loc.deleteBooklet, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { sortedFolders[$0] }
                            .filter { $0.id?.uuidString != defaultBookletID }
                        toDelete.forEach(ctx.delete)
                        try? ctx.save()
                    }
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
            .onAppear { setupDefaultBooklet() }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.lilyBackground.opacity(0), Color.lilyBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .allowsHitTesting(false)
            }
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
                    Button { showAddFolder = true } label: {
                        Image(systemName: "note.text.badge.plus")
                            .foregroundStyle(Color.lilyAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddFolder) { AddFolderView() }
            .sheet(isPresented: $showAddWord) { AddWordView(folder: nil) }
            .alert(loc.renameBooklet, isPresented: Binding(
                get: { folderToRename != nil },
                set: { if !$0 { folderToRename = nil } }
            )) {
                TextField(loc.nameLabel, text: $newFolderName)
                Button(loc.cancel, role: .cancel) { folderToRename = nil }
                Button(loc.done) {
                    folderToRename?.name = newFolderName.trimmingCharacters(in: .whitespaces)
                    try? ctx.save()
                    folderToRename = nil
                }
                .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // ── 底部列：設定按鈕（左）+ 搜尋按鈕（右）──────────────────────
            HStack {
                NavigationLink(destination: SettingsView()) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.lilyAccent)
                            .font(.system(size: 20))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                NavigationLink(destination: SearchView()) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.lilyAccent)
                            .font(.system(size: 20))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 0)
            .background(Color.lilyBackground)

            } // end VStack
        }
    }

    private func deleteFolders(at offsets: IndexSet) {
        withAnimation {
            offsets.map { sortedFolders[$0] }
                .filter { $0.id?.uuidString != defaultBookletID }
                .forEach(ctx.delete)
            try? ctx.save()
        }
    }

    // ── 預設筆記本設定 ────────────────────────────────────────────
    private func setupDefaultBooklet() {
        // 若已設定且存在，直接指派孤兒字卡
        if !defaultBookletID.isEmpty,
           folders.contains(where: { $0.id?.uuidString == defaultBookletID }) {
            assignOrphanWords()
            return
        }
        // 找看看是否已有名為 "Booklet" 的資料夾
        if let existing = folders.first(where: { $0.name == "Booklet" }) {
            defaultBookletID = existing.id?.uuidString ?? ""
            assignOrphanWords()
            return
        }
        // 建立新的預設筆記本
        let folder = CDFolder(context: ctx)
        let newID  = UUID()
        folder.id        = newID
        folder.name      = "Booklet"
        folder.createdAt = Date()
        folder.icon      = "note.text"
        folder.colorHex  = "#B8D4E8"
        defaultBookletID = newID.uuidString
        // 把所有現有字卡移進來
        for word in allWords { word.folder = folder }
        try? ctx.save()
    }

    private func assignOrphanWords() {
        guard let target = defaultFolder else { return }
        var changed = false
        for word in allWords where word.folder == nil {
            word.folder = target
            changed = true
        }
        if changed { try? ctx.save() }
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
            Image(systemName: "note.text")
                .foregroundStyle(Color.lilyAccent)
                .font(.system(size: 22))
                .frame(width: 22, height: 22)
                .clipped()
            Text(folder.name ?? "")
                .font(.system(size: 13)).foregroundStyle(Color.lilyText)
            Spacer()
            Text("\(folder.words?.count ?? 0)")
                .font(.system(size: 13)).foregroundStyle(Color.lilySecondaryText)
        }
        .padding(.vertical, 0)
    }
}

struct NotebookAddIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 44

            // Notebook body – square, stroke only
            let notebook = Path(roundedRect: CGRect(x: 9*s, y: 9*s,
                                                    width: 22*s, height: 22*s),
                                cornerRadius: 4*s)
            ctx.stroke(notebook, with: .color(Color.lilyAccent),
                       style: StrokeStyle(lineWidth: 2.2*s, lineCap: .round, lineJoin: .round))

            // Spiral binding dots on left edge
            let dotR = 2.2 * s
            for cy in [14.0, 20.0, 26.0] {
                let dot = Path(ellipseIn: CGRect(x: 9*s - dotR, y: cy*s - dotR,
                                                 width: dotR * 2, height: dotR * 2))
                ctx.fill(dot, with: .color(Color.lilyAccent))
            }

            // Content lines (two full-width, one shorter)
            let lineData: [(Double, Double)] = [(15, 27), (20, 27), (25, 22)]
            for (y, x2) in lineData {
                var line = Path()
                line.move(to: CGPoint(x: 14*s, y: y*s))
                line.addLine(to: CGPoint(x: x2*s, y: y*s))
                ctx.stroke(line, with: .color(Color.lilyAccent),
                           style: StrokeStyle(lineWidth: 1.8*s, lineCap: .round))
            }

            // Plus badge circle
            let badge = Path(ellipseIn: CGRect(x: 27*s, y: 27*s,
                                               width: 16*s, height: 16*s))
            ctx.fill(badge, with: .color(Color.lilyAccent))

            // Plus sign
            var v = Path()
            v.move(to: CGPoint(x: 35*s, y: 30*s))
            v.addLine(to: CGPoint(x: 35*s, y: 40*s))
            ctx.stroke(v, with: .color(.white),
                       style: StrokeStyle(lineWidth: 2*s, lineCap: .round))

            var h = Path()
            h.move(to: CGPoint(x: 30*s, y: 35*s))
            h.addLine(to: CGPoint(x: 40*s, y: 35*s))
            ctx.stroke(h, with: .color(.white),
                       style: StrokeStyle(lineWidth: 2*s, lineCap: .round))
        }
        .frame(width: 26, height: 26)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocalizationManager.shared)
}
