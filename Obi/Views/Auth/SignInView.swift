//
//  SignInView.swift
//  Obi
//
//  サインイン画面
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon & Title
            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)

                Text("Obi Notes")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("音楽レビューを記録しよう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                // Sign in with Apple Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await authViewModel.handleAppleSignIn(result: result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 32)

                // Development Mode Button
                Button(action: {
                    Task {
                        await authViewModel.signInWithDevMode()
                    }
                }) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("開発用ログイン")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.purple)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 32)
            }

            // Privacy Note
            Text("サインインすることで、利用規約とプライバシーポリシーに同意したものとみなされます")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .alert("エラー", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    SignInView(authViewModel: AuthenticationViewModel())
}
