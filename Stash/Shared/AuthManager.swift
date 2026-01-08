import Foundation
import Combine
import RealmSwift
import CryptoKit

/// 用户认证管理器
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: UserProfile?
    @Published var isLoggedIn: Bool = false
    
    private var realm: Realm {
        try! Realm()
    }
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - Session Management
    
    private func loadCurrentUser() {
        // 加载最后登录的用户
        if let user = realm.objects(UserProfile.self).first {
            currentUser = user
            isLoggedIn = true
        }
    }
    
    // MARK: - Email Authentication
    
    func register(email: String, password: String) -> Result<UserProfile, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 检查邮箱是否已存在
        if realm.objects(UserProfile.self).filter("email == %@", normalizedEmail).first != nil {
            return .failure(.emailAlreadyExists)
        }
        
        // 验证邮箱格式
        guard isValidEmail(normalizedEmail) else {
            return .failure(.invalidEmail)
        }
        
        // 验证密码强度
        guard password.count >= 6 else {
            return .failure(.weakPassword)
        }
        
        let passwordHash = hashPassword(password)
        let user = UserProfile(email: normalizedEmail, passwordHash: passwordHash)
        
        do {
            try realm.write {
                realm.add(user)
            }
            currentUser = user
            isLoggedIn = true
            
            // 初始化订阅信息
            CreditsManager.shared.initializeForNewUser()
            
            return .success(user)
        } catch {
            return .failure(.databaseError)
        }
    }
    
    func login(email: String, password: String) -> Result<UserProfile, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        let passwordHash = hashPassword(password)
        
        guard let user = realm.objects(UserProfile.self)
            .filter("email == %@ AND passwordHash == %@", normalizedEmail, passwordHash)
            .first else {
            return .failure(.invalidCredentials)
        }
        
        currentUser = user
        isLoggedIn = true
        return .success(user)
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
    }
    
    // MARK: - Third-party Login (Placeholder)
    
    func linkAppleAccount(userId: String) {
        guard let user = currentUser else { return }
        try? realm.write {
            if !user.linkedProviders.contains("apple") {
                user.linkedProviders.append("apple")
            }
        }
    }
    
    func linkGoogleAccount(userId: String) {
        guard let user = currentUser else { return }
        try? realm.write {
            if !user.linkedProviders.contains("google") {
                user.linkedProviders.append("google")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case emailAlreadyExists
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyExists: return "该邮箱已被注册"
        case .invalidEmail: return "邮箱格式无效"
        case .weakPassword: return "密码至少需要 6 位"
        case .invalidCredentials: return "邮箱或密码错误"
        case .databaseError: return "数据库错误，请重试"
        }
    }
}
