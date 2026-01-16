import Foundation
import Supabase

/// Supabase 客户端配置
enum SupabaseConfig {
    static let urlString = "https://aikwrkcamqqzwlceyppu.supabase.co"
    static let anonKey = "sb_publishable_gYkJVFE_5IbTSl82eqDiNQ_fM7GkVJG"
    
    /// 安全获取 URL
    static var url: URL? {
        URL(string: urlString)
    }
}

/// Supabase 服务（懒加载单例）
enum SupabaseService {
    /// 共享的 Supabase 客户端实例
    /// 使用 Optional 以处理初始化失败的情况
    private(set) static var shared: SupabaseClient? = {
        guard let url = SupabaseConfig.url else {
            print("SupabaseService: ERROR - Invalid Supabase URL")
            return nil
        }
        print("SupabaseService: Initializing Supabase client")
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }()
    
    /// 检查 Supabase 是否可用
    static var isAvailable: Bool {
        shared != nil
    }
}

/// 全局 supabase 变量（为了兼容现有代码）
/// 使用计算属性实现懒加载，避免启动时阻塞
var supabase: SupabaseClient {
    guard let client = SupabaseService.shared else {
        // 如果初始化失败，创建一个新的实例作为 fallback
        // 这比 crash 好，但功能可能受限
        print("SupabaseService: WARNING - Using fallback client")
        return SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.urlString)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    return client
}
