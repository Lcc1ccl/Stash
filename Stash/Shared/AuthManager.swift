import Foundation
import Combine
import Supabase

/// 用户认证管理器 - Supabase 版本
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var authStateTask: Task<Void, Never>?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        authStateTask = Task {
            do {
                let client = try requireSupabaseClient()
                for await (event, session) in client.auth.authStateChanges {
                    await MainActor.run {
                        switch event {
                        case .initialSession, .signedIn:
                            self.currentUser = session?.user
                            self.isLoggedIn = session?.user != nil
                            if let userId = session?.user.id {
                                Task {
                                    await CreditsManager.shared.loadUserCredits(userId: userId.uuidString)
                                }
                            } else {
                                CreditsManager.shared.resetForSignedOutState()
                            }
                        case .signedOut:
                            self.currentUser = nil
                            self.isLoggedIn = false
                            CreditsManager.shared.resetForSignedOutState()
                        default:
                            break
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Email Authentication
    
    func register(email: String, password: String) async -> Result<User, AuthError> {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = try requireSupabaseClient()
            let response = try await client.auth.signUp(email: email, password: password)
            let user = response.user
            
            // 初始化积分
            await CreditsManager.shared.initializeCredits(userId: user.id.uuidString)
            isLoading = false
            return .success(user)
        } catch {
            isLoading = false
            let authError = mapSupabaseError(error)
            errorMessage = authError.localizedDescription
            return .failure(authError)
        }
    }
    
    func login(email: String, password: String) async -> Result<User, AuthError> {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = try requireSupabaseClient()
            let session = try await client.auth.signIn(email: email, password: password)
            isLoading = false
            return .success(session.user)
        } catch {
            isLoading = false
            let authError = mapSupabaseError(error)
            errorMessage = authError.localizedDescription
            return .failure(authError)
        }
    }
    
    func logout() {
        Task {
            do {
                let client = try requireSupabaseClient()
                try await client.auth.signOut()
            } catch {
                await MainActor.run {
                    self.errorMessage = "登出失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func resetPassword(email: String) async -> Result<Void, AuthError> {
        do {
            let client = try requireSupabaseClient()
            try await client.auth.resetPasswordForEmail(email)
            return .success(())
        } catch {
            return .failure(mapSupabaseError(error))
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapSupabaseError(_ error: Error) -> AuthError {
        if let serviceError = error as? SupabaseServiceError {
            return .configurationError(serviceError.localizedDescription)
        }
        
        let message = error.localizedDescription.lowercased()
        
        if message.contains("already registered") || message.contains("already exists") {
            return .emailAlreadyExists
        } else if message.contains("invalid email") {
            return .invalidEmail
        } else if message.contains("weak password") || message.contains("password") {
            return .weakPassword
        } else if message.contains("invalid") || message.contains("credentials") {
            return .invalidCredentials
        } else if message.contains("network") || message.contains("connection") {
            return .networkError
        }
        
        return .unknown(error.localizedDescription)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case configurationError(String)
    case emailAlreadyExists
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let msg): return msg
        case .emailAlreadyExists: return "该邮箱已被注册"
        case .invalidEmail: return "邮箱格式无效"
        case .weakPassword: return "密码至少需要 6 位"
        case .invalidCredentials: return "邮箱或密码错误"
        case .networkError: return "网络连接失败，请检查网络"
        case .unknown(let msg): return msg
        }
    }
}
