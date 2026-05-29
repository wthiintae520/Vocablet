import SwiftUI

struct QuizView: View {
    let words: [CDWord]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject var loc: LocalizationManager

    @State private var currentIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var score = 0
    @State private var showResult = false
    @State private var options: [String] = []
    @State private var wrongWords: [CDWord] = []

    var currentWord: CDWord? { words.indices.contains(currentIndex) ? words[currentIndex] : nil }

    var body: some View {
        NavigationStack {
            Group {
                if showResult {
                    resultView.navigationTitle(loc.quizResultTitle)
                } else if let word = currentWord {
                    quizContent(word: word)
                        .navigationTitle("\(currentIndex + 1) / \(words.count)")
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.done) { dismiss() }.foregroundStyle(Color.lilySecondaryText)
                }
            }
        }
        .onAppear { loadOptions() }
    }

    private func quizContent(word: CDWord) -> some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(currentIndex) / Double(words.count))
                .tint(Color.lilyAccent).padding(.horizontal).padding(.top, 8)
            ScrollView {
                VStack(spacing: 20) {
                    questionCard(word: word).padding(.horizontal).padding(.top, 24)
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            optionButton(option: option, word: word).padding(.horizontal)
                        }
                    }
                    if selectedAnswer != nil {
                        Button(loc.nextQuestion) { nextQuestion() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.lilyAccent).cornerRadius(16)
                            .padding(.horizontal).padding(.top, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.lilyBackground)
    }

    private func questionCard(word: CDWord) -> some View {
        VStack(spacing: 12) {
            Text(loc.questionPrompt)
                .font(.system(size: 13)).foregroundStyle(Color.lilySecondaryText)
            Text(word.term ?? "")
                .font(.system(size: 30, weight: .bold)).foregroundStyle(Color.lilyText)
            if let pron = word.pronunciation, !pron.isEmpty {
                Text(pron).font(.system(size: 14, design: .monospaced)).foregroundStyle(Color.lilySecondaryText)
            }
            Button { SpeechService.shared.speak(word.term ?? "") } label: {
                Image(systemName: "speaker.wave.2.fill").foregroundStyle(Color.lilyAccent)
            }
        }
        .padding(24).frame(maxWidth: .infinity)
        .background(Color.lilyCard).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }

    private func optionButton(option: String, word: CDWord) -> some View {
        let isCorrect  = option == word.definition
        let isSelected = selectedAnswer == option
        let answered   = selectedAnswer != nil

        let bgColor: Color = {
            guard answered else { return Color.lilyCard }
            if isSelected && isCorrect  { return Color.lilyAccent.opacity(0.15) }
            if isSelected && !isCorrect { return Color(hex: "#F4A8C0").opacity(0.2) }
            if !isSelected && isCorrect { return Color.lilyAccent.opacity(0.15) }
            return Color.lilyCard
        }()
        let borderColor: Color = {
            guard answered else { return Color.lilyBorder }
            if isSelected && isCorrect  { return Color.lilyAccent }
            if isSelected && !isCorrect { return Color(hex: "#F4A8C0") }
            if !isSelected && isCorrect { return Color.lilyAccent }
            return Color.lilyBorder
        }()

        return Button {
            guard selectedAnswer == nil else { return }
            withAnimation(.spring(response: 0.3)) {
                selectedAnswer = option
                if isCorrect { score += 1 } else { wrongWords.append(word) }
            }
        } label: {
            HStack {
                Text(option)
                    .font(.system(size: 15)).foregroundStyle(Color.lilyText)
                    .multilineTextAlignment(.leading).lineLimit(3)
                Spacer()
                if answered {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.lilyAccent)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color(hex: "#F4A8C0"))
                    }
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(bgColor).cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
        }
        .disabled(answered)
    }

    private var resultView: some View {
        VStack(spacing: 28) {
            Spacer()
            let percent = words.isEmpty ? 0 : Int(Double(score) / Double(words.count) * 100)
            ZStack {
                Circle().stroke(Color.lilyBorder, lineWidth: 12)
                Circle().trim(from: 0, to: words.isEmpty ? 0 : Double(score) / Double(words.count))
                    .stroke(Color.lilyAccent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(percent)%").font(.system(size: 36, weight: .bold)).foregroundStyle(Color.lilyAccent)
                    Text("\(score)/\(words.count)").font(.system(size: 16)).foregroundStyle(Color.lilySecondaryText)
                }
            }
            .frame(width: 150, height: 150)

            Text(loc.quizResultMessage(percent: percent))
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Color.lilyText)

            if !wrongWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.reviewWordsLabel)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.lilySecondaryText)
                    ForEach(wrongWords) { w in
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill").foregroundStyle(Color(hex: "#F4A8C0"))
                            Text(w.term ?? "").font(.system(size: 15)).foregroundStyle(Color.lilyText)
                        }
                    }
                }
                .padding(16).background(Color.lilyCard).cornerRadius(16).padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button(loc.quizAgain) { restart() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.lilyAccent).frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.lilyAccent.opacity(0.12)).cornerRadius(14)
                Button(loc.quizFinish) { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.lilyAccent).cornerRadius(14)
            }
            .padding(.horizontal)
            Spacer()
        }
        .background(Color.lilyBackground)
    }

    private func loadOptions() {
        guard let word = currentWord else { return }
        var choices = [word.definition ?? ""]
        let others = words.filter { $0.id != word.id }.compactMap { $0.definition }.shuffled().prefix(3)
        choices.append(contentsOf: others)
        while choices.count < 4 { choices.append("—") }
        options = Array(choices.prefix(4)).shuffled()
    }

    private func nextQuestion() {
        if currentIndex + 1 >= words.count { withAnimation { showResult = true } }
        else { currentIndex += 1; selectedAnswer = nil; loadOptions() }
    }

    private func restart() {
        currentIndex = 0; selectedAnswer = nil; score = 0; showResult = false; wrongWords = []; loadOptions()
    }
}
