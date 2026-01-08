import Foundation
import RealmSwift

/// 用户账号信息模型
class UserProfile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var email: String = ""
    @Persisted var displayName: String = ""
    @Persisted var avatarUrl: String?
    @Persisted var passwordHash: String = ""  // SHA256 hash
    @Persisted var linkedProviders: List<String>  // "apple", "google"
    @Persisted var createdAt: Date = Date()
    
    convenience init(email: String, passwordHash: String, displayName: String? = nil) {
        self.init()
        self.email = email
        self.passwordHash = passwordHash
        self.displayName = displayName ?? email.components(separatedBy: "@").first ?? "User"
    }
}
