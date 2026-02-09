import Foundation
import Security

enum SecureKeyStoreError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save secure value (status: \(status))."
        case .loadFailed(let status):
            return "Failed to load secure value (status: \(status))."
        }
    }
}

final class SecureKeyStore {
    static let shared = SecureKeyStore()
    
    private let service = "com.chaosky.Stash.secure"
    
    private init() {}
    
    func save(_ value: String, for key: String) throws {
        let encoded = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
        
        var saveQuery = query
        saveQuery[kSecValueData as String] = encoded
        saveQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        
        let status = SecItemAdd(saveQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureKeyStoreError.saveFailed(status)
        }
    }
    
    func load(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SecureKeyStoreError.loadFailed(status)
        }
        guard let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}
