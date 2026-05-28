import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let c = PersistenceController(inMemory: true)
        let ctx = c.container.viewContext

        let folder = CDFolder(context: ctx)
        folder.id = UUID()
        folder.name = "日常英文"
        folder.createdAt = Date()
        folder.icon = "book.fill"
        folder.colorHex = "#7EC8A4"

        let sampleWords = [
            ("serendipity", "/ˌserənˈdɪpɪti/", "the occurrence of events by chance in a happy way",
             "Finding that café was pure serendipity.", "everyday"),
            ("ephemeral", "/ɪˈfemərəl/", "lasting for a very short time",
             "Youth is ephemeral.", "adjective"),
            ("resilience", "/rɪˈzɪliəns/", "the ability to recover from difficulties",
             "She showed great resilience after losing her job.", "everyday"),
        ]

        for (term, pron, def, ex, tagName) in sampleWords {
            let w = CDWord(context: ctx)
            w.id = UUID()
            w.term = term
            w.pronunciation = pron
            w.definition = def
            w.examples = ex
            w.isFavorite = term == "serendipity"
            w.masteryLevel = Int16.random(in: 0...3)
            w.createdAt = Date()
            w.reviewCount = Int16.random(in: 0...5)
            w.folder = folder

            let tag = CDTag(context: ctx)
            tag.id = UUID()
            tag.name = tagName
            tag.addToWords(w)
        }

        try? ctx.save()
        return c
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Vocablet")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
