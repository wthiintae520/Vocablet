import SwiftUI

struct WordDetailView: View {
    @ObservedObject var word: CDWord
    @Environment(\.managedObjectContext) private var ctx
    @StateObject private var speech = SpeechService.shared
    @State private var showEdit = false

    var tags: [CDTag] { (word.tags as? Set<CDTag>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? [] }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerCard
                    .padding(.horizontal)
                    .padding(.top, 16)

                if let pron = word.pronunciation, !pron.isEmpty {
                    pronunciationBanner(pron)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                if let examples = word.examples, !examples.isEmpty {
                    infoCard(title: "例句", icon: "text.quote", content: examples)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                if let notes = word.notes, !notes.isEmpty {
                    infoCard(title: "筆記", icon: "note.text", content: notes)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                if !tags.isEmpty {
                    tagsSection
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                statsSection
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.lilyBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        word.isFavorite.toggle()
                        try? ctx.save()
                    } label: {
                        Image(systemName: word.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(word.isFavorite ? Color(hex: "#F4A8C0") : Color.lilySecondaryText)
                    }
                    Button { showEdit = true } label: {
                        Image(systemName: "pencil.circle").foregroundStyle(Color.lilyAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) { AddWordView(word: word, folder: word.folder) }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(word.term ?? "")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                Spacer()
                Button {
                    speech.speak(word.term ?? "")
                } label: {
                    Image(systemName: speech.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.lilyAccent)
                        .symbolEffect(.pulse, isActive: speech.isSpeaking)
                }
            }

            Divider().background(Color.lilyBorder)

            Text(word.definition ?? "")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color.lilyText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
        .padding(20)
        .lilyCard()
    }

    private func pronunciationBanner(_ pron: String) -> some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundStyle(Color.lilyAccent)
            Text(pron)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(Color.lilySecondaryText)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.lilyAccent.opacity(0.08))
        .cornerRadius(12)
    }

    private func infoCard(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.lilySecondaryText)
            Text(content)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.lilyText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .lilyCard()
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("標籤", systemImage: "tag.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.lilySecondaryText)
            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    Text("#\(tag.name ?? "")")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color.lilyAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.lilyAccent.opacity(0.12))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .lilyCard()
    }

    private var statsSection: some View {
        HStack {
            StatItem(label: "複習次數", value: "\(word.reviewCount)")
            Divider().frame(height: 30).background(Color.lilyBorder)
            StatItem(label: "熟悉度",
                     value: ["新", "入門", "學習", "熟悉", "精通"].indices.contains(Int(word.masteryLevel))
                        ? ["新", "入門", "學習", "熟悉", "精通"][Int(word.masteryLevel)] : "精通")
            Divider().frame(height: 30).background(Color.lilyBorder)
            StatItem(label: "加入日期",
                     value: word.createdAt.map { DateFormatter.shortDate.string(from: $0) } ?? "-")
        }
        .padding(16)
        .lilyCard()
    }
}

struct StatItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Color.lilyAccent)
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.lilySecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.maxHeight }.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = item.sizeThatFits(.unspecified)
                item.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.maxHeight + spacing
        }
    }
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if current.width + size.width + (current.items.isEmpty ? 0 : spacing) > maxWidth, !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.items.append(view)
            current.width += size.width + (current.items.count == 1 ? 0 : spacing)
            current.maxHeight = max(current.maxHeight, size.height)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
    private struct Row {
        var items: [LayoutSubview] = []
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()
}
