import Foundation

enum AppRuntimeConfig {
    private static func value(env envKey: String, plist plistKey: String) -> String? {
        if let envValue = ProcessInfo.processInfo.environment[envKey], !envValue.isEmpty {
            return envValue
        }
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String,
           !plistValue.isEmpty {
            return plistValue
        }
        return nil
    }
    
    static var supabaseURLString: String? {
        value(env: "SUPABASE_URL", plist: "SUPABASE_URL")
    }
    
    static var supabaseAnonKey: String? {
        value(env: "SUPABASE_ANON_KEY", plist: "SUPABASE_ANON_KEY")
    }
    
    static var openAIAPIKey: String? {
        value(env: "OPENAI_API_KEY", plist: "OPENAI_API_KEY")
    }
}
