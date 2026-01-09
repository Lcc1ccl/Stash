import Foundation
import Supabase

/// Supabase 客户端配置
enum SupabaseConfig {
    static let url = URL(string: "https://aikwrkcamqqzwlceyppu.supabase.co")!
    static let anonKey = "sb_publishable_gYkJVFE_5IbTSl82eqDiNQ_fM7GkVJG"
}

/// 全局 Supabase 客户端
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
