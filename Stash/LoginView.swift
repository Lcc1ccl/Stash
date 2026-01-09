import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text(isRegistering ? "创建账号" : "登录")
                        .font(.title.bold())
                    
                    Text("使用邮箱登录以同步您的设置和积分")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Form
                VStack(spacing: 16) {
                    TextField("邮箱", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    SecureField("密码", text: $password)
                        .textContentType(isRegistering ? .newPassword : .password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    if isRegistering {
                        SecureField("确认密码", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    if let error = errorMessage ?? authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // Submit Button
                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isRegistering ? "注册" : "登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(authManager.isLoading)
                
                // Toggle Mode
                Button {
                    withAnimation {
                        isRegistering.toggle()
                        errorMessage = nil
                    }
                } label: {
                    Text(isRegistering ? "已有账号？登录" : "没有账号？注册")
                        .font(.subheadline)
                }
                
                // Forgot Password
                if !isRegistering {
                    Button {
                        Task {
                            await resetPassword()
                        }
                    } label: {
                        Text("忘记密码？")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Third-party Login
                VStack(spacing: 12) {
                    Text("或使用以下方式登录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Apple Sign In Button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Google Sign In Button
                    Button {
                        handleGoogleSignIn()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("使用 Google 登录")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submit() async {
        errorMessage = nil
        
        if isRegistering {
            guard password == confirmPassword else {
                errorMessage = "两次输入的密码不一致"
                return
            }
            
            let result = await authManager.register(email: email, password: password)
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        } else {
            let result = await authManager.login(email: email, password: password)
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "请先输入邮箱"
            return
        }
        
        let result = await authManager.resetPassword(email: email)
        switch result {
        case .success:
            errorMessage = "密码重置邮件已发送"
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        // Apple Sign In implementation - requires additional setup
        // This is a placeholder for the UI
        switch result {
        case .success(let auth):
            if let _ = auth.credential as? ASAuthorizationAppleIDCredential {
                // TODO: Integrate with Firebase Auth using Apple credential
                print("Apple Sign In success - integration pending")
            }
        case .failure(let error):
            errorMessage = "Apple 登录失败: \(error.localizedDescription)"
        }
    }
    
    private func handleGoogleSignIn() {
        // Google Sign In implementation - requires GoogleSignIn SDK
        // This is a placeholder for the UI
        errorMessage = "Google 登录功能即将上线"
    }
}

#Preview {
    LoginView()
}
