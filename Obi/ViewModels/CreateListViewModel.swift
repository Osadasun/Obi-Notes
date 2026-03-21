//
//  CreateListViewModel.swift
//  Obi
//
//  カスタムリスト作成用ViewModel
//

import Foundation
import Combine

@MainActor
class CreateListViewModel: ObservableObject {
    @Published var listName: String = ""
    @Published var description: String = ""
    @Published var isPublic: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isCreated: Bool = false

    private let supabaseService = SupabaseService.shared

    var canSubmit: Bool {
        !listName.isEmpty && !isSubmitting
    }

    func createList() async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil

        guard let userId = UserManager.shared.currentUserId else {
            errorMessage = "ユーザーが認証されていません"
            showError = true
            isSubmitting = false
            return
        }

        do {
            let newList = MusicList(
                id: UUID(),
                userId: userId,
                name: listName,
                description: description.isEmpty ? nil : description,
                isPublic: isPublic,
                type: .custom,
                defaultType: nil,
                createdAt: Date()
            )

            _ = try await supabaseService.createList(newList)

            print("✅ カスタムリスト作成成功")
            isCreated = true
        } catch {
            print("❌ カスタムリスト作成エラー: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}
