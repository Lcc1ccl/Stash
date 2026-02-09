import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditsManager = CreditsManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var selectedPlan: SubscriptionPlan = .free
    @State private var isUpgrading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("选择您的方案")
                            .font(.title.bold())
                            .accessibilityIdentifier("subscription.title")
                        Text("解锁更多 AI 功能")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    
                    // Login prompt if not logged in
                    if !authManager.isLoggedIn {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("请先登录以使用订阅功能")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Plan Cards
                    VStack(spacing: 16) {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                isCurrent: creditsManager.currentPlan == plan
                            ) {
                                selectedPlan = plan
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Features Comparison
                    VStack(alignment: .leading, spacing: 16) {
                        Text("功能对比")
                            .font(.headline)
                        
                        FeatureRow(feature: "每日积分", free: "10", plus: "50", pro: "200")
                        FeatureRow(feature: "AI 摘要", free: "✓", plus: "✓", pro: "✓")
                        FeatureRow(feature: "AI 聊天", free: "有限", plus: "✓", pro: "✓")
                        FeatureRow(feature: "优先支持", free: "—", plus: "✓", pro: "✓")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Subscribe Button
                    if selectedPlan != creditsManager.currentPlan && authManager.isLoggedIn {
                        Button {
                            Task {
                                await upgradePlan()
                            }
                        } label: {
                            if isUpgrading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(selectedPlan == .free ? "降级到 Free" : "升级到 \(selectedPlan.displayName)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPlan == .free ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(isUpgrading)
                        .accessibilityIdentifier("subscription.upgradeButton")
                    }
                    
                    Text("* 当前为模拟订阅，正式支付功能即将上线")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedPlan = creditsManager.currentPlan
            }
        }
    }
    
    private func upgradePlan() async {
        isUpgrading = true
        await creditsManager.upgradePlan(to: selectedPlan)
        isUpgrading = false
        dismiss()
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isCurrent: Bool
    let onSelect: () -> Void
    
    private var accentColor: Color {
        switch plan {
        case .free: return .gray
        case .plus: return .blue
        case .pro: return .orange
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(plan.displayName)
                        .font(.title2.bold())
                    
                    if isCurrent {
                        Text("当前")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.2))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.title2)
                    }
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text(plan.priceDescription)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(plan.dailyCredits) 积分/日")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: String
    let free: String
    let plus: String
    let pro: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(free)
                .font(.subheadline)
                .frame(width: 50, alignment: .center)
            
            Text(plus)
                .font(.subheadline)
                .frame(width: 50, alignment: .center)
            
            Text(pro)
                .font(.subheadline)
                .frame(width: 50, alignment: .center)
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    SubscriptionView()
}
