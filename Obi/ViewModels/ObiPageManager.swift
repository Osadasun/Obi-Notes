//
//  ObiPageManager.swift
//  Obi
//
//  Obiページ管理用ViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ObiPageManager: ObservableObject {
    @Published var pages: [ObiPageContent] = [.cardList]
    @Published var currentIndex: Int = 0
    private var isUserSwiping = false

    var currentPage: ObiPageContent {
        guard currentIndex >= 0 && currentIndex < pages.count else {
            return .cardList
        }
        return pages[currentIndex]
    }

    func navigateTo(_ page: ObiPageContent) {
        print("📱 Navigate to: \(page.id)")

        // 現在のインデックスより後ろにページがある場合は削除（履歴をクリーン）
        if currentIndex < pages.count - 1 {
            print("📱 Cleaning up forward history: removing \(pages.count - currentIndex - 1) pages")
            pages.removeSubrange((currentIndex + 1)..<pages.count)
        }

        pages.append(page)
        currentIndex = pages.count - 1
        printPageStack()
    }

    private func printPageStack() {
        print("📚 Page stack [\(pages.count) pages]:")
        for (index, page) in pages.enumerated() {
            let marker = index == currentIndex ? "👉" : "  "
            print("  \(marker) [\(index)] \(page.id) - \(page.title)")
        }
    }

    func goBack() {
        print("📱 Go back: index \(currentIndex) → \(currentIndex - 1)")
        guard pages.count > 1, currentIndex > 0 else { return }

        printPageStack()

        // インデックスだけ変更して、ページ削除は遅延実行
        let targetIndex = currentIndex - 1
        currentIndex = targetIndex

        // アニメーション完了後にページを削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            if self.pages.count > self.currentIndex + 1 {
                print("📱 Remove page at index \(self.pages.count - 1)")
                self.pages.removeLast()
                self.printPageStack()
            }
        }
    }

    func handlePageChange(to index: Int) {
        print("📱 Page changed to: \(index)")
        printPageStack()

        // ユーザーがスワイプで戻った場合
        if index < currentIndex && pages.count > index + 1 {
            // インデックスを更新
            currentIndex = index

            // 後ろのページを削除
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self else { return }
                while self.pages.count > self.currentIndex + 1 {
                    print("📱 Remove trailing page")
                    self.pages.removeLast()
                }
                self.printPageStack()
            }
        }
    }

    func updateCurrentPage(_ newPage: ObiPageContent) {
        print("📱 Update current page: \(newPage.id)")
        guard currentIndex >= 0 && currentIndex < pages.count else { return }
        pages[currentIndex] = newPage
        printPageStack()
    }
}
