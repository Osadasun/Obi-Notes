//
//  EditProfileView.swift
//  Obi
//
//  プロフィール編集画面
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @Binding var editedDisplayName: String

    var body: some View {
        ScrollView {
                VStack(spacing: 32) {
                    // プロフィール画像
                    VStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                )

                            // 編集ボタン
                            Circle()
                                .fill(Color.black)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                                .offset(x: -10, y: -10)
                        }
                        .frame(height: 200)
                    }
                    .padding(.top, 16)

                    // ユーザー名入力フィールド
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("", text: $editedDisplayName)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
    }
}

#Preview {
    EditProfileView(
        viewModel: ProfileViewModel(),
        isPresented: .constant(true),
        editedDisplayName: .constant("ユーザー名")
    )
}
