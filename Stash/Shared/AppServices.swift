import Foundation
import RealmSwift
import Supabase

protocol AuthServiceProtocol: AnyObject {
    var currentUser: User? { get }
    var isLoggedIn: Bool { get }
    func logout()
}

protocol CreditsServiceProtocol: AnyObject {
    func refreshCreditsForOperation() async
    func hasEnoughCredits(_ amount: Double) async -> Bool
    func consumeCreditsForOperation(_ amount: Double) async -> Bool
}

protocol AIClientProtocol: AnyObject {
    func analyzeContent(title: String, url: String) async -> OpenAIClient.AIAnalysisResult
    func chat(query: String, context: String) async -> String
}

protocol StorageServiceProtocol: AnyObject {
    func saveItem(_ item: AssetItem)
    func fetchItems() -> Results<AssetItem>?
}

protocol SnapshotServiceProtocol: AnyObject {
    func capture(urlString: String, completion: @escaping (String?) -> Void)
}

struct AppServices {
    var auth: AuthServiceProtocol
    var credits: CreditsServiceProtocol
    var aiClient: AIClientProtocol
    var storage: StorageServiceProtocol
    var snapshot: SnapshotServiceProtocol
    
    static var shared = AppServices(
        auth: AuthManager.shared,
        credits: CreditsManager.shared,
        aiClient: OpenAIClient.shared,
        storage: StorageManager.shared,
        snapshot: WebSnapshotService.shared
    )
}

extension AuthManager: AuthServiceProtocol {}

extension CreditsManager: CreditsServiceProtocol {
    func refreshCreditsForOperation() async {
        await refreshCreditsIfNeeded()
    }
    
    func hasEnoughCredits(_ amount: Double) async -> Bool {
        canAfford(amount)
    }
    
    func consumeCreditsForOperation(_ amount: Double) async -> Bool {
        await consumeCredits(amount)
    }
}

extension OpenAIClient: AIClientProtocol {}

extension StorageManager: StorageServiceProtocol {
    func saveItem(_ item: AssetItem) {
        save(item)
    }
    
    func fetchItems() -> Results<AssetItem>? {
        fetchAll()
    }
}

extension WebSnapshotService: SnapshotServiceProtocol {
    func capture(urlString: String, completion: @escaping (String?) -> Void) {
        captureSnapshot(for: urlString, completion: completion)
    }
}
