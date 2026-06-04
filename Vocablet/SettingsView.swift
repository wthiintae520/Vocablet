import SwiftUI

// MARK: - UI Language Picker

struct UILanguagePickerView: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(AppLanguage.allCases) { lang in
            Button {
                withAnimation { loc.language = lang }
                dismiss()
            } label: {
                HStack(spacing: 14) {
                    Text(lang.displayName)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.lilyText)
                    Spacer()
                    if loc.language == lang {
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
        .navigationTitle(loc.uiLanguageLabel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var loc: LocalizationManager
    @AppStorage("notificationEnabled")  private var notificationEnabled = true
    @AppStorage("notificationHour")     private var notificationHour = 20
    @AppStorage("notificationMinute")   private var notificationMinute = 0
    @AppStorage("pronunciationAccent")  private var pronunciationAccent = "en-US"
    @AppStorage("phoneticSystem")       private var phoneticSystem = "KK"
    @AppStorage("showMasteryDots")      private var showMasteryDots = true

    @State private var notificationTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    var body: some View {
        NavigationStack {
            List {
                // App icon header
                Section {
                    appIconHeader
                } header: {
                    Color.clear.frame(height: 0)
                }

                // ── 語言設定 ──────────────────────────────
                Section {
                    // UI 語言
                    NavigationLink { UILanguagePickerView() } label: {
                        HStack(spacing: 12) {
                            settingIcon("character.bubble.fill", color: "#A8C8E8")
                            Text(loc.uiLanguageLabel)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.lilyText)
                            Spacer()
                            Text(loc.language.displayName)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.lilySecondaryText)
                        }
                    }

                    // 發音腔調（美式 / 英式）
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            settingIcon("waveform", color: "#B8D4E8")
                            Text(loc.pronunciationLabel)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.lilyText)
                        }
                        Picker("", selection: $pronunciationAccent) {
                            Text(loc.americanEng).tag("en-US")
                            Text(loc.britishEng).tag("en-GB")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)

                    // 音標系統（KK / IPA）
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            settingIcon("textformat.abc", color: "#B8D4E8")
                            Text(loc.phoneticSystemLabel)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.lilyText)
                        }
                        Picker("", selection: $phoneticSystem) {
                            Text(loc.kkSystem).tag("KK")
                            Text(loc.ipaSystem).tag("IPA")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)

                    // 試聽
                    Button {
                        SpeechService.shared.speak("The quick brown fox jumps over the lazy dog.")
                    } label: {
                        HStack(spacing: 12) {
                            settingIcon("speaker.wave.2.fill", color: "#B8D4E8")
                            Text(loc.testPronun)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.lilyText)
                            Spacer()
                            Text(loc.play)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.lilySecondaryText)
                        }
                    }

                } header: {
                    Text(loc.languageSection)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                } footer: {
                    Text(loc.langFooter)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // ── 通知設定 ──────────────────────────────
                Section {
                    Toggle(isOn: $notificationEnabled) {
                        HStack(spacing: 12) {
                            settingIcon("bell.fill", color: "#F4A8C0")
                            Text(loc.dailyReminder)
                                .font(.system(size: 16))
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
                        DatePicker(loc.reminderTime, selection: $notificationTime,
                                   displayedComponents: .hourAndMinute)
                            .font(.system(size: 16))
                            .onChange(of: notificationTime) { _, date in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                notificationHour = comps.hour ?? 20
                                notificationMinute = comps.minute ?? 0
                                NotificationService.shared.scheduleReviewReminder(
                                    hour: notificationHour, minute: notificationMinute)
                            }
                    }
                } header: {
                    Text(loc.notifSection)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // ── 顯示設定 ──────────────────────────────
                Section {
                    Toggle(isOn: $showMasteryDots) {
                        HStack(spacing: 12) {
                            settingIcon("circle.fill", color: "#A8C8E8")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.showMasteryDots)
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.lilyText)
                                Text(loc.showMasteryDotsHint)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.lilySecondaryText)
                            }
                        }
                    }
                    .tint(Color.lilyAccent)
                } header: {
                    Text(loc.displaySection)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // ── iCloud 同步 ───────────────────────────
                Section {
                    HStack(spacing: 12) {
                        settingIcon("icloud.fill", color: "#A8C8E8")
                        Text(loc.iCloudSync)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.lilyText)
                        Spacer()
                        Text(loc.autoSync)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.lilySecondaryText)
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.lilyAccent)
                    }
                } header: {
                    Text(loc.syncSection)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // ── AI 設定 ──────────────────────────────
                Section {
                    HStack(spacing: 12) {
                        settingIcon("sparkles", color: "#3A6651")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.aiSection)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.lilyText)
                            Text(loc.aiPoweredBy)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.lilySecondaryText)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.lilyAccent)
                    }
                } footer: {
                    Text(loc.aiProxyFooter)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lilySecondaryText)
                }

                // ── 關於 ──────────────────────────────────
                Section {
                    LabeledContent(loc.versionLabel, value: "1.0.0")
                        .font(.system(size: 15))
                    LabeledContent(loc.developerLabel, value: "Vocablet Team")
                        .font(.system(size: 15))
                } header: {
                    Text(loc.aboutSection)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lilySecondaryText)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationTitle(loc.settingsTitle)
            .onAppear { loadNotificationTime() }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func settingIcon(_ name: String, color: String) -> some View {
        Image(systemName: name)
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Color(hex: color))
            .cornerRadius(8)
    }

    private var appIconHeader: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#B8D4E8"), Color(hex: "#A8C8E8")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 36)).foregroundStyle(.white)
                }
                Text(loc.appName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.lilyText)
                Text(loc.appTagline)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.lilySecondaryText)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }

    private func loadNotificationTime() {
        var comps = DateComponents()
        comps.hour = notificationHour; comps.minute = notificationMinute
        notificationTime = Calendar.current.date(from: comps) ?? Date()
    }
}

#Preview {
    SettingsView().environmentObject(LocalizationManager.shared)
}
