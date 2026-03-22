//
//  PageViewController.swift
//  Obi
//
//  UIPageViewControllerのSwiftUIラッパー
//

import SwiftUI
import UIKit

struct PageViewController: UIViewControllerRepresentable {
    var pages: [AnyView]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        // 初期ページを設定
        let initialController = UIHostingController(rootView: pages[currentPage])
        initialController.view.tag = currentPage
        pageViewController.setViewControllers(
            [initialController],
            direction: .forward,
            animated: false
        )

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // 現在表示中のページのタグを取得
        let currentIndex = pageViewController.viewControllers?.first?.view.tag ?? 0

        // 現在のページと異なる場合のみ更新
        if currentIndex != currentPage {
            let direction: UIPageViewController.NavigationDirection = currentIndex < currentPage ? .forward : .reverse

            let controller = UIHostingController(rootView: pages[currentPage])
            controller.view.tag = currentPage

            pageViewController.setViewControllers(
                [controller],
                direction: direction,
                animated: true
            )
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController

        init(_ pageViewController: PageViewController) {
            self.parent = pageViewController
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            let index = viewController.view.tag
            guard index > 0 else {
                return nil
            }

            let controller = UIHostingController(rootView: parent.pages[index - 1])
            controller.view.tag = index - 1
            return controller
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            let index = viewController.view.tag
            guard index < parent.pages.count - 1 else {
                return nil
            }

            let controller = UIHostingController(rootView: parent.pages[index + 1])
            controller.view.tag = index + 1
            return controller
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let currentViewController = pageViewController.viewControllers?.first {
                let index = currentViewController.view.tag
                parent.currentPage = index
            }
        }
    }
}
