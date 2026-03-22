//
//  ImageColorExtractor.swift
//  Obi
//
//  画像から色を抽出するユーティリティ
//

import SwiftUI
import UIKit

extension UIImage {
    /// 画像の平均色を取得
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }

    /// 画像の支配的な色を取得（暗めにして帯に適した色に）
    func dominantColor() -> UIColor? {
        guard let averageColor = averageColor() else { return nil }

        // 色を暗くして帯に適した色に変換
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        averageColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // 明度を下げて、彩度を少し上げる
        let darkenedBrightness = brightness * 0.4 // 40%の明度に
        let enhancedSaturation = min(saturation * 1.2, 1.0) // 彩度を少し上げる

        return UIColor(hue: hue, saturation: enhancedSaturation, brightness: darkenedBrightness, alpha: 1.0)
    }
}

extension Color {
    init(uiColor: UIColor) {
        self.init(uiColor)
    }
}
