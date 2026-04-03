//
//  MasonryLayout.swift
//  Obi
//
//  2カラムのMasonryレイアウト（瀑布流）
//

import SwiftUI

struct MasonryLayout: Layout {
    var spacing: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = calculateHeight(width: width, subviews: subviews)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // 2カラム + 中央のスペース16pxを考慮
        // bounds.widthは既にpaddingが適用された幅
        let availableWidth = bounds.width
        let columnWidth = (availableWidth - spacing) / 2
        var columnHeights: [CGFloat] = [0, 0]

        print("🧱 [MasonryLayout] placeSubviews called")
        print("   bounds.width: \(bounds.width), spacing: \(spacing), columnWidth: \(columnWidth)")
        print("   subviews.count: \(subviews.count)")

        for (index, subview) in subviews.enumerated() {
            let shortestColumn = columnHeights.firstIndex(of: columnHeights.min() ?? 0) ?? 0
            // 左カラム(0): bounds.minX
            // 右カラム(1): bounds.minX + columnWidth + spacing
            let x = bounds.minX + CGFloat(shortestColumn) * (columnWidth + spacing)
            let y = bounds.minY + columnHeights[shortestColumn]

            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            print("   [\(index)] column: \(shortestColumn), size: \(size), x: \(x), y: \(y)")
            print("   [\(index)] columnHeights before: [\(columnHeights[0]), \(columnHeights[1])]")

            subview.place(at: CGPoint(x: x, y: y), proposal: .init(width: columnWidth, height: size.height))

            columnHeights[shortestColumn] += size.height + spacing
            print("   [\(index)] columnHeights after: [\(columnHeights[0]), \(columnHeights[1])]")
        }
    }

    private func calculateHeight(width: CGFloat, subviews: Subviews) -> CGFloat {
        // 2カラム + 中央のスペース16pxを考慮
        let columnWidth = (width - spacing) / 2
        var columnHeights: [CGFloat] = [0, 0]

        for subview in subviews {
            let shortestColumn = columnHeights.firstIndex(of: columnHeights.min() ?? 0) ?? 0
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            columnHeights[shortestColumn] += size.height + spacing
        }

        return columnHeights.max() ?? 0
    }
}
