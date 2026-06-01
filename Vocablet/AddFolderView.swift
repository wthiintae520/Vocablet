import SwiftUI

struct AddFolderView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationManager

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(loc.folderNameLabel) {
                    TextField(loc.folderNameHint, text: $name)
                        .font(.system(size: 16))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.lilyBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.addFolderTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: "#3A3230"))
                }
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
        folder.id = UUID()
        folder.name = name.trimmingCharacters(in: .whitespaces)
        folder.createdAt = Date()
        folder.icon = "note.text"
        folder.colorHex = "#B8D4E8"
        try? ctx.save()
        dismiss()
    }
}
