import SwiftUI

struct WordDetailView: View {
    @ObservedObject var word: CDWord
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var speech = SpeechService.shared
    @AppStorage("phoneticSystem") private var phoneticSystem = "KK"
    @State private var showEdit = false

    var tags: [CDTag] { (word.tags as? Set<CDTag>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? [] }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerCard.padding(.horizontal).padding(.top, 16)
                if let def = word.definition, !def.isEmpty {
                    definitionCard(def).padding(.horizontal).padding(.top, 12)
                }
                if let ex = word.examples, !ex.isEmpty {
                    exampleCard(ex).padding(.horizontal).padding(.top, 12)
                }
                if let n = word.notes, !n.isEmpty {
                    infoCard(title: loc.notes, icon: "note.text", content: n)
                        .padding(.horizontal).padding(.top, 12)
                }
                if !tags.isEmpty {
                    tagsSection.padding(.horizontal).padding(.top, 12)
                }
                statsSection.padding(.horizontal).padding(.top, 12).padding(.bottom, 32)
            }
        }
        .background(Color.lilyBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil.circle").foregroundStyle(Color.lilyAccent)
                }
            }
        }
        .sheet(isPresented: $showEdit) { AddWordView(word: word, folder: word.folder) }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Text(word.term ?? "")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.lilyText)
                // 詞性 badge
                if let pos = word.partOfSpeech, !pos.isEmpty {
                    Text(pos)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.lilyAccent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.lilyAccent.opacity(0.12))
                        .cornerRadius(8)
                }
                Spacer()
            }
            // 音標
            if let pron = phoneticToShow(), !pron.isEmpty {
                HStack {
                    Button { speech.speak(word.term ?? "") } label: {
                        Image(systemName: "waveform")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.lilyAccent.opacity(0.7))
                            .symbolEffect(.pulse, isActive: speech.isSpeaking)
                    }
                    Text(pron)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color.lilySecondaryText)
                    Spacer()
                }
            }
            // 中文翻譯
            if let cn = word.chineseTranslation, !cn.isEmpty {
                HStack {
                    Text(cn)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.lilyAccent)
                    Spacer()
                }
            }
        }
        .padding(20)
        .lilyCard()
    }

    private func definitionCard(_ def: String) -> some View {
        Text(def)
            .font(.system(size: 17))
            .foregroundStyle(Color.lilyText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(4)
            .padding(20)
            .lilyCard()
    }

    private func phoneticToShow() -> String? {
        if phoneticSystem == "IPA" {
            let ipa = word.phoneticIPA ?? ""
            return ipa.isEmpty ? nil : ipa
        } else {
            let kk = word.pronunciation ?? ""
            return kk.isEmpty ? nil : kk
        }
    }

    private func exampleCard(_ sentence: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.examples)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lilySecondaryText)
            Text(sentence)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let exTr = word.exampleTranslation, !exTr.isEmpty {
                Text(exTr)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.lilySecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16).lilyCard()
    }

    private func infoCard(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lilySecondaryText)
            Text(content)
                .font(.system(size: 15))
                .foregroundStyle(Color.lilyText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16).lilyCard()
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(loc.tags, systemImage: "tag.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lilySecondaryText)
            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    Text("#\(tag.name ?? "")")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.lilyAccent)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.lilyAccent.opacity(0.12))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16).lilyCard()
    }

    private var statsSection: some View {
        HStack {
            StatItem(label: loc.reviewCount, value: "\(word.reviewCount)")
            Divider().frame(height: 30).background(Color.lilyBorder)
            StatItem(label: loc.mastery, value: loc.masteryText(word.masteryLevel))
            Divider().frame(height: 30).background(Color.lilyBorder)
            StatItem(label: loc.addedDate,
                     value: word.createdAt.map { DateFormatter.shortDate.string(from: $0) } ?? "-")
        }
        .padding(16).lilyCard()
    }
}

struct StatItem: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.lilyAccent)
            Text(label).font(.system(size: 12)).foregroundStyle(Color.lilySecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let h = rows.map { $0.maxHeight }.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: h)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for item in row.items {
                item.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += item.sizeThatFits(.unspecified).width + spacing
            }
            y += row.maxHeight + spacing
        }
    }
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []; var current = Row()
        let maxW = proposal.width ?? .infinity
        for view in subviews {
            let sz = view.sizeThatFits(.unspecified)
            if current.width + sz.width + (current.items.isEmpty ? 0 : spacing) > maxW, !current.items.isEmpty {
                rows.append(current); current = Row()
            }
            current.items.append(view)
            current.width += sz.width + (current.items.count == 1 ? 0 : spacing)
            current.maxHeight = max(current.maxHeight, sz.height)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
    private struct Row { var items: [LayoutSubview] = []; var width: CGFloat = 0; var maxHeight: CGFloat = 0 }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .none; return f
    }()
}
