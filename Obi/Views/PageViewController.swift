//
//  PageViewController.swift
//  Obi
//
//  UIPageViewControllerのSwiftUIラッパー
//

import SwiftUI
import UIKit

struct PageViewController<Page: View>: UIViewControllerRepresentable {
    var pages: [Page]
    var pageIds: [String] // ページを識別するためのID配列
    @Binding var currentIndex: Int
    var onPageChange: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        print("📄 [PageViewController] makeUIViewController called")
        print("📄 [PageViewController]   Pages count: \(pages.count)")
        print("📄 [PageViewController]   Current index: \(currentIndex)")
        print("📄 [PageViewController]   Page IDs: \(pageIds)")

        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        // 初期ページを設定（アニメーションなし）
        if !context.coordinator.controllers.isEmpty && currentIndex < context.coordinator.controllers.count {
            pageViewController.setViewControllers(
                [context.coordinator.controllers[currentIndex]],
                direction: .forward,
                animated: false,
                completion: nil
            )
            print("📄 [PageViewController]   ✅ Set initial viewController at index \(currentIndex)")
        } else {
            print("📄 [PageViewController]   ⚠️ Cannot set initial viewController: empty controllers or invalid index")
        }

        // CoordinatorにUIPageViewControllerの参照を保存
        context.coordinator.pageViewController = pageViewController

        // 初期状態でスクロール有効/無効を設定
        DispatchQueue.main.async {
            context.coordinator.updateScrollEnabled()
        }

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        print("📄 [PageViewController] updateUIViewController called")
        print("📄 [PageViewController]   Current index binding: \(currentIndex)")
        print("📄 [PageViewController]   Coordinator current index: \(context.coordinator.currentIndex ?? -1)")
        print("📄 [PageViewController]   Pages count: \(pages.count)")

        // ページ数またはページIDが変わった場合、コントローラー配列を更新
        let countChanged = context.coordinator.controllers.count != pages.count
        let idsChanged = context.coordinator.pageIds != pageIds

        if countChanged || idsChanged {
            if countChanged {
                print("📄 [PageViewController]   🔄 Controllers count changed: \(context.coordinator.controllers.count) → \(pages.count)")
            }
            if idsChanged {
                print("📄 [PageViewController]   🔄 Page IDs changed")
                print("📄 [PageViewController]     Old IDs: \(context.coordinator.pageIds)")
                print("📄 [PageViewController]     New IDs: \(pageIds)")
            }
            context.coordinator.controllers = pages.map { UIHostingController(rootView: $0) }
            context.coordinator.pageIds = pageIds
            print("📄 [PageViewController]   ✅ Updated controllers array")
        }

        // 現在のインデックスが範囲内かチェック
        guard currentIndex >= 0 && currentIndex < pages.count else {
            print("📄 [PageViewController]   ⚠️ Index out of range: \(currentIndex) (pages.count: \(pages.count))")
            return
        }

        // インデックスが変わった場合のみページを切り替え
        guard context.coordinator.currentIndex != currentIndex else {
            print("📄 [PageViewController]   ℹ️ Index unchanged, no navigation needed")
            return
        }

        let shouldAnimate = context.coordinator.currentIndex != nil

        let direction: UIPageViewController.NavigationDirection =
            currentIndex > (context.coordinator.currentIndex ?? 0) ? .forward : .reverse

        print("📄 [PageViewController]   📍 Navigating: \(context.coordinator.currentIndex ?? -1) → \(currentIndex)")
        print("📄 [PageViewController]     Direction: \(direction == .forward ? "forward" : "reverse")")
        print("📄 [PageViewController]     Animated: \(shouldAnimate)")

        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentIndex]],
            direction: direction,
            animated: shouldAnimate,
            completion: nil
        )

        context.coordinator.currentIndex = currentIndex
        print("📄 [PageViewController]   ✅ setViewControllers completed")

        // 最初のページにいる場合はスクロールを無効化（外側のScrollViewがジェスチャーを処理できるように）
        context.coordinator.updateScrollEnabled()
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var controllers: [UIHostingController<Page>] = []
        var pageIds: [String] = []
        var currentIndex: Int?
        weak var pageViewController: UIPageViewController?

        init(_ pageViewController: PageViewController) {
            self.parent = pageViewController
            self.controllers = pageViewController.pages.map { UIHostingController(rootView: $0) }
            self.pageIds = pageViewController.pageIds
            self.currentIndex = pageViewController.currentIndex
        }

        func updateScrollEnabled() {
            guard let pageViewController = pageViewController else {
                print("📄 [Coordinator] updateScrollEnabled: pageViewController is nil")
                return
            }

            print("📄 [Coordinator] updateScrollEnabled called")
            print("📄 [Coordinator]   Current index: \(currentIndex ?? -1)")
            print("📄 [Coordinator]   Controllers count: \(controllers.count)")

            // UIPageViewControllerの内部ScrollViewを取得
            var foundScrollView = false
            for view in pageViewController.view.subviews {
                if let scrollView = view as? UIScrollView {
                    foundScrollView = true
                    // 最初のページにいる場合はスクロールを無効化
                    // これにより外側のScrollViewがジェスチャーを処理できる
                    let shouldDisableScroll = currentIndex == 0
                    let newValue = !shouldDisableScroll
                    let oldValue = scrollView.isScrollEnabled

                    if oldValue != newValue {
                        scrollView.isScrollEnabled = newValue
                        print("📄 [Coordinator]   ✅ Changed scroll enabled: \(oldValue) → \(newValue) (reason: \(shouldDisableScroll ? "at index 0, disable for outer ScrollView" : "not at index 0, enable for paging"))")
                    } else {
                        print("📄 [Coordinator]   ℹ️ Scroll enabled unchanged: \(newValue) (at index \(currentIndex ?? -1))")
                    }
                }
            }

            if !foundScrollView {
                print("📄 [Coordinator]   ⚠️ No UIScrollView found in UIPageViewController.view.subviews")
            }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(where: { $0 === viewController }),
                  index > 0 else {
                return nil
            }
            return controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            // 「次へ」のスワイプを無効化（Obiタブ内では詳細画面に進むスワイプは不要）
            return nil
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            print("📄 [Coordinator] didFinishAnimating called")
            print("📄 [Coordinator]   Finished: \(finished)")
            print("📄 [Coordinator]   Completed: \(completed)")

            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(where: { $0 === visibleViewController }) {
                print("📄 [Coordinator]   ✅ Page transition completed to index: \(index)")
                print("📄 [Coordinator]   Previous index: \(currentIndex ?? -1)")
                currentIndex = index
                parent.currentIndex = index
                print("📄 [Coordinator]   📢 Calling onPageChange(\(index))")
                parent.onPageChange(index)

                // ページ変更後にスクロール状態を更新
                updateScrollEnabled()
            } else {
                print("📄 [Coordinator]   ⚠️ Transition not completed or visible VC not found")
            }
        }
    }
}
