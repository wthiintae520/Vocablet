import SwiftUI

struct WordDetailView: View {
    @ObservedObject var word: CDWord
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var speech = SpeechService.shared
    @AppStorage("phoneticSystem") private var phoneticSystem = "KK"
    @AppStorage("addWordFieldOrder") private var fieldOrderRaw: String =
        ReorderableField.allCases.map { $0.rawValue }.joined(separator: ",")
    @State private var showEdit = false

    private var fieldOrder: [ReorderableField] {
        let saved = fieldOrderRaw.split(separator: ",").compactMap { ReorderableField(rawValue: String($0)) }
        let missing = ReorderableField.allCases.filter { !saved.contains($0) }
        return saved + missing
    }

    var tags: [CDTag] { (word.tags as? Set<CDTag>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? [] }

    private var masteryColor: Color {
        switch word.masteryLevel {
        case 0: return Color(hex: "#F4A8A8")  // 紅
        case 1: return Color(hex: "#F4C8A0")  // 橘
        case 2: return Color(hex: "#A8D4B0")  // 綠
        case 3: return Color(hex: "#A8C8E8")  // 藍
        default: return Color(hex: "#C4A8E4")  // 紫
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerCard.padding(.horizontal).padding(.top, 16)
                ForEach(fieldOrder, id: \.self) { field in
                    detailCard(for: field)
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
                    Image(systemName: "pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.lilyAccent)
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

    @ViewBuilder
    private func detailCard(for field: ReorderableField) -> some View {
        switch field {
        case .definition:
            if let def = word.definition, !def.isEmpty {
                definitionCard(def).padding(.horizontal).padding(.top, 12)
            }
        case .example:
            if let ex = word.examples, !ex.isEmpty {
                exampleCard(ex).padding(.horizontal).padding(.top, 12)
            }
        case .notes:
            if let n = word.notes, !n.isEmpty {
                infoCard(title: loc.notes, icon: "note.text", content: n)
                    .padding(.horizontal).padding(.top, 12)
            }
        case .image:
            if let data = word.imageData, let uiImage = UIImage(data: data) {
                imageCard(uiImage).padding(.horizontal).padding(.top, 12)
            }
        }
    }

    private func imageCard(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .cornerRadius(14)
            .padding(8)
            .lilyCard()
    }

    private func definitionCard(_ def: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.englishDefinition)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lilySecondaryText)
            Text(def)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#3A3230"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
        .padding(20)
        .lilyCard()
    }

    private func phoneticToShow() -> String? {
        let ipa = word.phoneticIPA ?? ""
        let kk  = word.pronunciation ?? ""
        if phoneticSystem == "IPA" {
            return !ipa.isEmpty ? ipa : (!kk.isEmpty ? kk : nil)
        } else {
            return !kk.isEmpty ? kk : (!ipa.isEmpty ? ipa : nil)
        }
    }

    private func exampleCard(_ sentence: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.examples)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lilySecondaryText)
            Text(sentence)
                .font(.system(size: 14))
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
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lilySecondaryText)
            Text(content)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#8A8A8A"))
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
        HStack(alignment: .bottom) {
            VStack(spacing: 4) {
                Circle()
                    .fill(masteryColor)
                    .frame(width: 10, height: 10)
                    .frame(maxWidth: .infinity)
                Text("\(word.masteryLevel * 25)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.lilyAccent)
                Text(loc.mastery)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lilySecondaryText)
            }
            .frame(maxWidth: .infinity)
            Divider().frame(height: 30).background(Color.lilyBorder)
            StatItem(label: loc.addedDate,
                     value: word.createdAt.map { DateFormatter.shortDateTime.string(from: $0) } ?? "-")
            Divider().frame(height: 30).background(Color.lilyBorder)
            StatItem(label: loc.modifiedDate,
                     value: word.updatedAt.map { DateFormatter.shortDateTime.string(from: $0) } ?? "-")
        }
        .padding(16).lilyCard()
    }
}

struct StatItem: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.lilyAccent)
                .multilineTextAlignment(.center)
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
    static let shortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM d, yyyy HH:mm"
        return f
    }()
}
