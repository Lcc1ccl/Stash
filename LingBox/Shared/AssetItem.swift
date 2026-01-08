import Foundation
import RealmSwift

class AssetItem: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var url: String
    @Persisted var title: String
    @Persisted var imageUrl: String?
    @Persisted var sourceAppName: String
    @Persisted var createdAt: Date
    @Persisted var isReviewed: Bool = false
    @Persisted var summary: String?
    @Persisted var tags: List<String>
    @Persisted var coverEmoji: String = "📦"
    @Persisted var coverColor: String = "bg-gray-100"

    convenience init(url: String, title: String, imageUrl: String? = nil, sourceAppName: String = "Unknown", summary: String? = nil, tags: [String] = [], coverEmoji: String = "📦", coverColor: String = "bg-gray-100") {
        self.init()
        self.id = UUID()
        self.url = url
        self.title = title
        self.imageUrl = imageUrl
        self.sourceAppName = sourceAppName
        self.createdAt = Date()
        self.isReviewed = false
        self.summary = summary
        self.tags.append(objectsIn: tags)
        self.coverEmoji = coverEmoji
        self.coverColor = coverColor
    }
}
