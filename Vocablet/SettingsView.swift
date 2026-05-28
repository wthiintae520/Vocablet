import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 20
    @AppStorage("notificationMinute") private var notificationMinute = 0

    @State private var notificationTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    appIcon
                } header: {
                    Color.clear.frame(height: 0)
                }

                Section {
                    Toggle(isOn: $notificationEnabled) {
                        Label("每日複習提醒", systemImage: "bell.fill")
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

                Section {
                    HStack {
                        Label("iCloud 同步", systemImage: "icloud.fill")
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

    private var appIcon: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [Color(hex: "#7EC8A4"), Color(hex: "#A8C8E8")],
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
