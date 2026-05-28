import SwiftUI
import CoreData

struct FlashcardView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDWord.term)]) private var allWords: FetchedResults<CDWord>
    @FetchRequest(sortDescriptors: [SortDescriptor(\CDFolder.name)]) private var folders: FetchedResults<CDFolder>

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var selectedFolder: CDFolder? = nil
    @State private var showResult = false
    @State private var knownCount = 0
    @State private var unknownCount = 0
    @State private var dragOffset: CGFloat = 0

    var words: [CDWord] {
        if let folder = selectedFolder {
            return (folder.words?.allObjects as? [CDWord] ?? []).shuffled()
        }
        return Array(allWords).shuffled()
    }

    @State private var sessionWords: [CDWord] = []

    var currentWord: CDWord? {
        guard !sessionWords.isEmpty, sessionWords.indices.contains(currentIndex) else { return nil }
        return sessionWords[currentIndex]
    }

    var progress: Double {
        guard !sessionWords.isEmpty else { return 0 }
        return Double(currentIndex) / Double(sessionWords.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                folderPicker
                    .padding(.horizontal)
                    .padding(.top, 8)

                if sessionWords.isEmpty {
                    emptyState
                } else if currentIndex >= sessionWords.count {
                    resultView
                } else {
                    cardArea
                }
            }
            .background(Color.lilyBackground)
            .navigationTitle("字卡複習")
            .onAppear { startSession() }
        }
    }

    private var folderPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "全部", isSelected: selectedFolder == nil) {
                    selectedFolder = nil
                    startSession()
                }
                ForEach(folders) { folder in
                    filterChip(label: folder.name ?? "", isSelected: selectedFolder == folder) {
                        selectedFolder = folder
                        startSession()
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color.lilyAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.lilyAccent : Color.lilyAccent.opacity(0.1))
                .cornerRadius(20)
        }
    }

    private var cardArea: some View {
        VStack(spacing: 24) {
            ProgressView(value: progress)
                .tint(Color.lilyAccent)
                .padding(.horizontal)
                .padding(.top, 8)

            Text("\(currentIndex + 1) / \(sessionWords.count)")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Color.lilySecondaryText)

            if let word = currentWord {
                flashCard(word: word)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { dragOffset = $0.translation.width }
                            .onEnded { value in
                                if value.translation.width < -100 { swipe(known: false) }
                                else if value.translation.width > 100 { swipe(known: true) }
                                else { withAnimation(.spring()) { dragOffset = 0 } }
                            }
                    )

                HStack(spacing: 40) {
                    actionButton(icon: "xmark.circle.fill", color: Color(hex: "#F4A8C0"),
                                 label: "不熟") { swipe(known: false) }
                    Button {
                        SpeechService.shared.speak(word.term ?? "")
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.lilyAccent)
                    }
                    actionButton(icon: "checkmark.circle.fill", color: Color.lilyAccent,
                                 label: "認識") { swipe(known: true) }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private func flashCard(word: CDWord) -> some View {
        ZStack {
            cardFace(isFront: true, word: word).opacity(isFlipped ? 0 : 1)
            cardFace(isFront: false, word: word).opacity(isFlipped ? 1 : 0).rotation3DEffect(.degrees(180), axis: (0, 1, 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (0, 1, 0))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture { isFlipped.toggle() }
        .padding(.horizontal, 20)
    }

    private func cardFace(isFront: Bool, word: CDWord) -> some View {
        VStack(spacing: 16) {
            Spacer()
            if isFront {
                Text(word.term ?? "")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                    .multilineTextAlignment(.center)
                if let pron = word.pronunciation, !pron.isEmpty {
                    Text(pron)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Color.lilySecondaryText)
                }
                Text("點擊翻轉查看定義")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.lilyBorder)
                    .padding(.top, 8)
            } else {
                Text(word.definition ?? "")
                    .font(.system(size: 20, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                if let ex = word.examples, !ex.isEmpty {
                    Text(ex)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(24)
        .background(Color.lilyCard)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
    }

    private func actionButton(icon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 44)).foregroundStyle(color)
                Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.lilySecondaryText)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView("沒有單字可複習", systemImage: "rectangle.on.rectangle.angled",
                               description: Text("請先新增單字"))
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.lilyAccent)
            Text("複習完成！")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.lilyText)
            HStack(spacing: 40) {
                VStack {
                    Text("\(knownCount)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Color.lilyAccent)
                    Text("認識").font(.system(size: 14, design: .rounded)).foregroundStyle(Color.lilySecondaryText)
                }
                VStack {
                    Text("\(unknownCount)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Color(hex: "#F4A8C0"))
                    Text("不熟").font(.system(size: 14, design: .rounded)).foregroundStyle(Color.lilySecondaryText)
                }
            }
            Button("再來一次") { startSession() }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 200, height: 52)
                .background(Color.lilyAccent)
                .cornerRadius(16)
            Spacer()
        }
    }

    private func startSession() {
        sessionWords = words
        currentIndex = 0
        isFlipped = false
        knownCount = 0
        unknownCount = 0
        dragOffset = 0
    }

    private func swipe(known: Bool) {
        if known { knownCount += 1 } else { unknownCount += 1 }
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = known ? 400 : -400
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            updateMastery(word: sessionWords[currentIndex], known: known)
            currentIndex += 1
            isFlipped = false
            dragOffset = 0
        }
    }

    private func updateMastery(word: CDWord, known: Bool) {
        word.reviewCount += 1
        word.lastReviewed = Date()
        if known { word.masteryLevel = min(word.masteryLevel + 1, 4) }
        else { word.masteryLevel = max(word.masteryLevel - 1, 0) }
        try? ctx.save()
    }
}

#Preview {
    FlashcardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
