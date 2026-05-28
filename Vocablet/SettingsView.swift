import SwiftUI
import AVFoundation

// MARK: - Language Model

struct LearningLanguage: Identifiable {
    let id: String        // BCP 47，用於 AVSpeechSynthesisVoice
    let flag: String
    let displayName: String  // 中文名稱
    let nativeName: String   // 語言原生名稱

    static let all: [LearningLanguage] = [
        .init(id: "en-US", flag: "🇺🇸", displayName: "英語（美式）",   nativeName: "English (US)"),
        .init(id: "en-GB", flag: "🇬🇧", displayName: "英語（英式）",   nativeName: "English (UK)"),
        .init(id: "ja-JP", flag: "🇯🇵", displayName: "日語",           nativeName: "日本語"),
        .init(id: "ko-KR", flag: "🇰🇷", displayName: "韓語",           nativeName: "한국어"),
        .init(id: "fr-FR", flag: "🇫🇷", displayName: "法語",           nativeName: "Français"),
        .init(id: "de-DE", flag: "🇩🇪", displayName: "德語",           nativeName: "Deutsch"),
        .init(id: "es-ES", flag: "🇪🇸", displayName: "西班牙語",       nativeName: "Español"),
        .init(id: "it-IT", flag: "🇮🇹", displayName: "義大利語",       nativeName: "Italiano"),
        .init(id: "pt-BR", flag: "🇧🇷", displayName: "葡萄牙語（巴西）",nativeName: "Português (BR)"),
        .init(id: "zh-CN", flag: "🇨🇳", displayName: "中文（普通話）", nativeName: "普通话"),
        .init(id: "zh-TW", flag: "🇹🇼", displayName: "中文（台灣）",   nativeName: "中文（台灣）"),
    ]

    /// 從系統 Locale 推導預設語言代碼
    static var systemDefault: String {
        let lang   = Locale.current.language.languageCode?.identifier ?? "en"
        let region = Locale.current.region?.identifier ?? "US"
        let candidate = "\(lang)-\(region)"
        if all.contains(where: { $0.id == candidate }) { return candidate }
        if let match = all.first(where: { $0.id.hasPrefix(lang + "-") }) { return match.id }
        return "en-US"
    }
}

// MARK: - Language Picker View

struct LanguagePickerView: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss

    /// 只顯示裝置上真的有聲音資源的語言
    private var available: [LearningLanguage] {
        let installed = Set(AVSpeechSynthesisVoice.speechVoices().map { $0.language })
        return LearningLanguage.all.filter { lang in
            installed.contains(where: { $0.hasPrefix(lang.id.prefix(2)) })
        }
    }

    var body: some View {
        List(available) { lang in
            Button {
                selectedCode = lang.id
                dismiss()
            } label: {
                HStack(spacing: 14) {
                    Text(lang.flag)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.displayName)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(Color.lilyText)
                        Text(lang.nativeName)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color.lilySecondaryText)
                    }

                    Spacer()

                    if selectedCode == lang.id {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.lilyAccent)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.lilyBackground)
        .navigationTitle("選擇語言")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("notificationEnabled")  private var notificationEnabled = true
    @AppStorage("notificationHour")     private var notificationHour = 20
    @AppStorage("notificationMinute")   private var notificationMinute = 0
    @AppStorage("learningLanguage")     private var learningLanguage = LearningLanguage.systemDefault

    @State private var notificationTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    private var selectedLanguage: LearningLanguage? {
        LearningLanguage.all.first { $0.id == learningLanguage }
    }

    var body: some View {
        NavigationStack {
            List {
                // App icon header
                Section {
                    appIconHeader
                } header: {
                    Color.clear.frame(height: 0)
                }

                // 語言切換
                Section {
                    NavigationLink {
                        LanguagePickerView(selectedCode: $learningLanguage)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "waveform")
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: "#A8C8E8"))
                                .cornerRadius(8)

                            Text("發音語言")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(Color.lilyText)

                            Spacer()

                            if let lang = selectedLanguage {
                                Text("\(lang.flag) \(lang.displayName)")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(Color.lilySecondaryText)
                            }
                        }
                    }

                    // 試聽按鈕
                    Button {
                        SpeechService.shared.speak("Hello, this is a pronunciation test.")
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.lilyAccent)
                                .cornerRadius(8)

                            Text("試聽發音")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(Color.lilyText)

                            Spacer()

                            Text("播放")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(Color.lilySecondaryText)
                        }
                    }
                } header: {
                    Text("語言設定")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                } footer: {
                    Text("預設跟隨系統語言。切換語言後，字卡與單字詳情的發音將同步更新。")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // 通知設定
                Section {
                    Toggle(isOn: $notificationEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: "#F4A8C0"))
                                .cornerRadius(8)
                            Text("每日複習提醒")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(Color.lilyText)
                        }
                    }
                    .tint(Color.lilyAccent)
                    .onChange(of: notificationEnabled) { _, enabled in
                        if enabled {
                            NotificationService.shared.scheduleReviewReminder(
                                hour: notificationHour, minute: notificationMinute)
                        } else {
                            NotificationService.shared.cancelReminder()
                        }
                    }

                    if notificationEnabled {
                        DatePicker("提醒時間", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .font(.system(size: 16, design: .rounded))
                            .onChange(of: notificationTime) { _, date in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                notificationHour = comps.hour ?? 20
                                notificationMinute = comps.minute ?? 0
                                NotificationService.shared.scheduleReviewReminder(
                                    hour: notificationHour, minute: notificationMinute)
                            }
                    }
                } header: {
                    Text("通知設定")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // iCloud
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "#A8C8E8"))
                            .cornerRadius(8)
                        Text("iCloud 同步")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(Color.lilyText)
                        Spacer()
                        Text("自動")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color.lilySecondaryText)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.lilyAccent)
                    }
                } header: {
                    Text("同步")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // 關於
                Section {
                    LabeledContent("版本", value: "1.0.0")
                        .font(.system(size: 15, design: .rounded))
                    LabeledContent("開發者", value: "Vocablet Team")
                        .font(.system(size: 15, design: .rounded))
                } header: {
                    Text("關於")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.lilySecondaryText)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationTitle("設定")
            .onAppear { loadNotificationTime() }
        }
    }

    // MARK: - Subviews

    private var appIconHeader: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#7EC8A4"), Color(hex: "#A8C8E8")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                Text("Vocablet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.lilyText)
                Text("你的英文單字小幫手")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.lilySecondaryText)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private func loadNotificationTime() {
        var comps = DateComponents()
        comps.hour = notificationHour
        comps.minute = notificationMinute
        notificationTime = Calendar.current.date(from: comps) ?? Date()
    }
}

#Preview {
    SettingsView()
}
