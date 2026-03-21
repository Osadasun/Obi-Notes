//
//  CreateListView.swift
//  Obi
//
//  カスタムリスト作成画面
//

import SwiftUI

struct CreateListView: View {
    @StateObject private var viewModel = CreateListViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("リスト情報")) {
                    TextField("リスト名", text: $viewModel.listName)
                    TextField("説明（任意）", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("公開する", isOn: $viewModel.isPublic)
                } footer: {
                    Text("公開すると他のユーザーがこのリストを見ることができます")
                }
            }
            .navigationTitle("新しいリスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        Task {
                            await viewModel.createList()
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: viewModel.isCreated) { _, isCreated in
                if isCreated {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    CreateListView()
}
