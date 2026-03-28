//
//  ScreenMetrics.swift
//  Obi
//
//  画面サイズとレイアウト定数を管理
//

import SwiftUI

/// 画面サイズとレイアウト定数を提供するシングルトン
class ScreenMetrics {
    static let shared = ScreenMetrics()

    private init() {}

    /// 現在の画面サイズ
    var screenSize: CGSize {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return .zero
        }
        return window.bounds.size
    }

    /// 画面の横幅
    var screenWidth: CGFloat {
        screenSize.width
    }

    /// 画面の縦幅
    var screenHeight: CGFloat {
        screenSize.height
    }

    /// Safe Areaの上部インセット
    var safeAreaTop: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
    }

    /// Safe Areaの下部インセット
    var safeAreaBottom: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

/// レイアウト定数
struct LayoutConstants {
    /// 水平方向の標準padding
    static let horizontalPadding: CGFloat = 24

    /// ボタン間の標準spacing
    static let buttonSpacing: CGFloat = 16

    /// 検索ボタンの基本padding
    static let searchButtonBasePadding: CGFloat = 14

    /// 検索ボタンの追加padding（progressベース）
    static let searchButtonAdditionalPadding: CGFloat = 6

    /// 追加ボタンの縮小時の幅
    static let addButtonCollapsedWidth: CGFloat = 64

    /// 検索アイコンの幅
    static let searchIconWidth: CGFloat = 20

    /// 検索ボタンとTextFieldの右側余白
    static let searchButtonTrailingMargin: CGFloat = 24
}

/// SwiftUI Viewから使いやすいEnvironment Key
struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
}

/// GeometryReaderを使わずに画面サイズを取得するためのViewModifier
struct ScreenSizeModifier: ViewModifier {
    @State private var screenSize: CGSize = ScreenMetrics.shared.screenSize

    func body(content: Content) -> some View {
        content
            .environment(\.screenSize, screenSize)
            .onAppear {
                screenSize = ScreenMetrics.shared.screenSize
            }
    }
}

extension View {
    func withScreenSize() -> some View {
        modifier(ScreenSizeModifier())
    }
}
