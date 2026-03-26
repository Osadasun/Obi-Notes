//
//  ShareViewController.swift
//  ShareExtension
//
//  Share Extension のエントリーポイント
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 共有されたURLを取得
        extractSharedURL { [weak self] url in
            guard let self = self, let url = url else {
                self?.showError(message: "URLを取得できませんでした")
                return
            }

            // SwiftUI Viewを表示
            self.showShareView(with: url)
        }
    }

    private func extractSharedURL(completion: @escaping (URL?) -> Void) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            completion(nil)
            return
        }

        // URL型のデータを取得
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let url = item as? URL {
                        completion(url)
                    } else if let data = item as? Data, let urlString = String(data: data, encoding: .utf8), let url = URL(string: urlString) {
                        completion(url)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            // テキストとして取得を試みる
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let urlString = item as? String, let url = URL(string: urlString) {
                        completion(url)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }

    private func showShareView(with url: URL) {
        let shareView = ShareExtensionView(url: url) { [weak self] success in
            self?.completeRequest(success: success)
        }

        let hostingController = UIHostingController(rootView: shareView)
        hostingController.view.backgroundColor = .systemBackground

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "閉じる", style: .default) { [weak self] _ in
            self?.completeRequest(success: false)
        })
        present(alert, animated: true)
    }

    private func completeRequest(success: Bool) {
        if success {
            // 成功時はコンテキストを完了
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        } else {
            // キャンセル時はエラーで完了
            let error = NSError(domain: "ShareExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])
            extensionContext?.cancelRequest(withError: error)
        }
    }
}
