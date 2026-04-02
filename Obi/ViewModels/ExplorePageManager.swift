//
//  ExplorePageManager.swift
//  Obi
//
//  Exploreページ管理用ViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ExplorePageManager: ObservableObject {
    @Published var pages: [ExplorePageContent] = [.feed]
    @Published var currentIndex: Int = 0

    var currentPage: ExplorePageContent {
        guard currentIndex >= 0 && currentIndex < pages.count else {
            return .feed
        }
        return pages[currentIndex]
    }

    func navigateTo(_ page: ExplorePageContent) {
        print("🌍 [ExplorePageManager] navigateTo called")
        print("🌍 [ExplorePageManager]   Target page: \(page.id)")
        print("🌍 [ExplorePageManager]   Current state BEFORE: index=\(currentIndex), pages.count=\(pages.count)")

        // 現在のインデックスより後ろにページがある場合は削除（履歴をクリーン）
        if currentIndex < pages.count - 1 {
            let pagesToRemove = pages.count - currentIndex - 1
            print("🌍 [ExplorePageManager]   Cleaning forward history: removing \(pagesToRemove) pages")
            pages.removeSubrange((currentIndex + 1)..<pages.count)
            print("🌍 [ExplorePageManager]   After cleanup: pages.count=\(pages.count)")
        }

        pages.append(page)
        currentIndex = pages.count - 1
        print("🌍 [ExplorePageManager]   Current state AFTER: index=\(currentIndex), pages.count=\(pages.count)")
        printPageStack()
    }

    private func printPageStack() {
        print("📚 Explore page stack [\(pages.count) pages]:")
        for (index, page) in pages.enumerated() {
            let marker = index == currentIndex ? "👉" : "  "
            print("  \(marker) [\(index)] \(page.id) - \(page.title)")
        }
    }

    func goBack() {
        print("🌍 [ExplorePageManager] goBack called")
        print("🌍 [ExplorePageManager]   Current state: index=\(currentIndex), pages.count=\(pages.count)")

        guard pages.count > 1, currentIndex > 0 else {
            print("🌍 [ExplorePageManager]   ⚠️ Cannot go back: at root or invalid state")
            return
        }

        printPageStack()

        // インデックスだけ変更して、ページ削除は遅延実行
        let targetIndex = currentIndex - 1
        print("🌍 [ExplorePageManager]   Setting index: \(currentIndex) → \(targetIndex)")
        currentIndex = targetIndex

        // アニメーション完了後にページを削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else {
                print("🌍 [ExplorePageManager]   ⚠️ Self deallocated during goBack cleanup")
                return
            }
            print("🌍 [ExplorePageManager]   Cleanup timer fired: index=\(self.currentIndex), pages.count=\(self.pages.count)")
            if self.pages.count > self.currentIndex + 1 {
                let pageToRemove = self.pages.last?.id ?? "unknown"
                print("🌍 [ExplorePageManager]   Removing page: \(pageToRemove) at index \(self.pages.count - 1)")
                self.pages.removeLast()
                print("🌍 [ExplorePageManager]   After removal: pages.count=\(self.pages.count)")
                self.printPageStack()
            } else {
                print("🌍 [ExplorePageManager]   ⚠️ No page to remove (pages.count=\(self.pages.count), currentIndex=\(self.currentIndex))")
            }
        }
    }

    func handlePageChange(to index: Int) {
        print("🌍 [ExplorePageManager] handlePageChange called")
        print("🌍 [ExplorePageManager]   Target index: \(index)")
        print("🌍 [ExplorePageManager]   Current state BEFORE: index=\(currentIndex), pages.count=\(pages.count)")
        printPageStack()

        // ユーザーがスワイプで戻った場合
        if index < currentIndex && pages.count > index + 1 {
            print("🌍 [ExplorePageManager]   ✅ Swipe back detected: \(currentIndex) → \(index)")
            // インデックスを更新
            currentIndex = index
            print("🌍 [ExplorePageManager]   Index updated to: \(currentIndex)")

            // 後ろのページを削除
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self else {
                    print("🌍 [ExplorePageManager]   ⚠️ Self deallocated during handlePageChange cleanup")
                    return
                }
                print("🌍 [ExplorePageManager]   Cleanup timer fired: index=\(self.currentIndex), pages.count=\(self.pages.count)")
                var removedCount = 0
                while self.pages.count > self.currentIndex + 1 {
                    let pageToRemove = self.pages.last?.id ?? "unknown"
                    print("🌍 [ExplorePageManager]   Removing trailing page: \(pageToRemove)")
                    self.pages.removeLast()
                    removedCount += 1
                }
                print("🌍 [ExplorePageManager]   Removed \(removedCount) trailing pages, final count: \(self.pages.count)")
                self.printPageStack()
            }
        } else if index == currentIndex {
            print("🌍 [ExplorePageManager]   ℹ️ Same index, no action needed")
        } else {
            print("🌍 [ExplorePageManager]   ⚠️ Unexpected state: index=\(index), currentIndex=\(currentIndex), pages.count=\(pages.count)")
        }
    }
}
