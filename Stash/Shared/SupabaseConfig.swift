import Foundation
import Supabase

enum SupabaseConfigError: LocalizedError {
    case missingURL
    case invalidURL(String)
    case missingAnonKey
    
    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Supabase URL is missing. Set SUPABASE_URL in environment or Info.plist."
        case .invalidURL(let raw):
            return "Supabase URL is invalid: \(raw)"
        case .missingAnonKey:
            return "Supabase anon key is missing. Set SUPABASE_ANON_KEY in environment or Info.plist."
        }
    }
}

struct ResolvedSupabaseConfig {
    let url: URL
    let anonKey: String
}

enum SupabaseConfig {
    static func resolve() -> Result<ResolvedSupabaseConfig, SupabaseConfigError> {
        guard let rawURL = AppRuntimeConfig.supabaseURLString else {
            return .failure(.missingURL)
        }
        guard let url = URL(string: rawURL) else {
            return .failure(.invalidURL(rawURL))
        }
        guard let anonKey = AppRuntimeConfig.supabaseAnonKey else {
            return .failure(.missingAnonKey)
        }
        
        return .success(ResolvedSupabaseConfig(url: url, anonKey: anonKey))
    }
}

/// Supabase 服务（懒加载单例）
enum SupabaseService {
    private(set) static var shared: SupabaseClient? = {
        switch SupabaseConfig.resolve() {
        case .success(let config):
            print("SupabaseService: Initializing Supabase client")
            return SupabaseClient(
                supabaseURL: config.url,
                supabaseKey: config.anonKey
            )
        case .failure(let error):
            print("SupabaseService: \(error.localizedDescription)")
            return nil
        }
    }()
    
    static var configurationError: SupabaseConfigError? {
        switch SupabaseConfig.resolve() {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    static var isAvailable: Bool {
        shared != nil
    }
}

enum SupabaseServiceError: LocalizedError {
    case unavailable(SupabaseConfigError?)
    
    var errorDescription: String? {
        switch self {
        case .unavailable(let configError):
            return configError?.localizedDescription ?? "Supabase client is unavailable."
        }
    }
}

func requireSupabaseClient() throws -> SupabaseClient {
    guard let client = SupabaseService.shared else {
        throw SupabaseServiceError.unavailable(SupabaseService.configurationError)
    }
    return client
}

var supabase: SupabaseClient? {
    SupabaseService.shared
}
