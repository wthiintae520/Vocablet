import SwiftUI

struct AddFolderView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationManager

    @State private var name = ""
    @State private var selectedColor = LilyPalette.folderColors[0]
    @State private var selectedIcon = LilyPalette.folderIcons[0]

    var body: some View {
        NavigationStack {
            Form {
                Section(loc.folderNameLabel) {
                    TextField(loc.folderNameHint, text: $name)
                        .font(.system(size: 16))
                }

                Section(loc.iconLabel) {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                        ForEach(LilyPalette.folderIcons, id: \.self) { icon in
                            Button { selectedIcon = icon } label: {
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

                Section(loc.colorLabel) {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                        ForEach(LilyPalette.folderColors, id: \.self) { hex in
                            Button { selectedColor = hex } label: {
                                ZStack {
                                    Circle().fill(Color(hex: hex)).frame(width: 44, height: 44)
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
            .navigationTitle(loc.addFolderTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.cancel) { dismiss() }.foregroundStyle(Color.lilySecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.done) { save() }
                        .foregroundStyle(Color.lilyAccent).fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let folder = CDFolder(context: ctx)
        folder.id = UUID(); folder.name = name.trimmingCharacters(in: .whitespaces)
        folder.createdAt = Date(); folder.colorHex = selectedColor; folder.icon = selectedIcon
        try? ctx.save(); dismiss()
    }
}
