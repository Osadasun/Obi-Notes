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
        print("📄 PageViewController makeUIViewController - creating with \(pages.count) pages, currentIndex: \(currentIndex)")

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
            print("📄 Set initial viewController at index \(currentIndex)")
        }

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // ページ数またはページIDが変わった場合、コントローラー配列を更新
        let countChanged = context.coordinator.controllers.count != pages.count
        let idsChanged = context.coordinator.pageIds != pageIds

        if countChanged || idsChanged {
            if countChanged {
                print("📄 PageViewController update: controllers count changed \(context.coordinator.controllers.count) → \(pages.count)")
            }
            if idsChanged {
                print("📄 PageViewController update: page IDs changed")
                print("  Old IDs: \(context.coordinator.pageIds)")
                print("  New IDs: \(pageIds)")
            }
            context.coordinator.controllers = pages.map { UIHostingController(rootView: $0) }
            context.coordinator.pageIds = pageIds
        }

        // 現在のインデックスが範囲内かチェック
        guard currentIndex >= 0 && currentIndex < pages.count else { return }

        // インデックスが変わった場合のみページを切り替え
        guard context.coordinator.currentIndex != currentIndex else {
            return
        }

        let shouldAnimate = context.coordinator.currentIndex != nil

        let direction: UIPageViewController.NavigationDirection =
            currentIndex > (context.coordinator.currentIndex ?? 0) ? .forward : .reverse

        print("📄 PageViewController update: index \(context.coordinator.currentIndex ?? -1) → \(currentIndex), animated: \(shouldAnimate)")

        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentIndex]],
            direction: direction,
            animated: shouldAnimate,
            completion: nil
        )

        context.coordinator.currentIndex = currentIndex
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var controllers: [UIHostingController<Page>] = []
        var pageIds: [String] = []
        var currentIndex: Int?

        init(_ pageViewController: PageViewController) {
            self.parent = pageViewController
            self.controllers = pageViewController.pages.map { UIHostingController(rootView: $0) }
            self.pageIds = pageViewController.pageIds
            self.currentIndex = pageViewController.currentIndex
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
            guard let index = controllers.firstIndex(where: { $0 === viewController }),
                  index < controllers.count - 1 else {
                return nil
            }
            return controllers[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(where: { $0 === visibleViewController }) {
                currentIndex = index
                parent.currentIndex = index
                parent.onPageChange(index)
            }
        }
    }
}
