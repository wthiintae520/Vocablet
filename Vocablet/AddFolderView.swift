import SwiftUI

struct AddFolderView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = LilyPalette.folderColors[0]
    @State private var selectedIcon = LilyPalette.folderIcons[0]

    var body: some View {
        NavigationStack {
            Form {
                Section("資料夾名稱") {
                    TextField("例：日常英文、商務用語", text: $name)
                        .font(.system(size: 16, design: .rounded))
                }

                Section("圖示") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                        ForEach(LilyPalette.folderIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(selectedIcon == icon ? .white : Color.lilyText)
                                    .frame(width: 52, height: 52)
                                    .background(selectedIcon == icon ? Color.lilyAccent : Color.lilyBackground)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("顏色") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                        ForEach(LilyPalette.folderColors, id: \.self) { hex in
                            Button {
                                selectedColor = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 44, height: 44)
                                    if selectedColor == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationTitle("新增資料夾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Color.lilySecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { save() }
                        .foregroundStyle(Color.lilyAccent)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let folder = CDFolder(context: ctx)
        folder.id = UUID()
        folder.name = name.trimmingCharacters(in: .whitespaces)
        folder.createdAt = Date()
        folder.colorHex = selectedColor
        folder.icon = selectedIcon
        try? ctx.save()
        dismiss()
    }
}
