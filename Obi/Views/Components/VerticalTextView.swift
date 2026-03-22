//
//  VerticalTextView.swift
//  Obi
//
//  縦書きテキストコンポーネント（CoreText使用）
//

import SwiftUI
import UIKit

struct VerticalTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let maxLines: Int

    func makeUIView(context: Context) -> VerticalTextUIView {
        let view = VerticalTextUIView()
        view.text = text
        view.font = font
        view.textColor = textColor
        view.maxLines = maxLines
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: VerticalTextUIView, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.textColor = textColor
        uiView.maxLines = maxLines
        uiView.setNeedsDisplay()
    }
}

class VerticalTextUIView: UIView {
    var text: String = ""
    var font: UIFont = UIFont.systemFont(ofSize: 12)
    var textColor: UIColor = .black
    var maxLines: Int = 1

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 座標系を変換（左上を原点に）
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // 縦書き用の属性を設定
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .verticalGlyphForm: 1
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // CoreTextで縦書きレンダリング
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

        // 縦書き用のパスを作成（右から左へ）
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height), transform: nil)

        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil)

        // 90度回転して縦書きに
        context.saveGState()
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)
        context.rotate(by: -CGFloat.pi / 2)
        context.translateBy(x: -bounds.height / 2, y: -bounds.width / 2)

        CTFrameDraw(frame, context)

        context.restoreGState()
    }
}
