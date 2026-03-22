//
//  ListCard.swift
//  Obi
//
//  リストカード共通コンポーネント
//

import SwiftUI

struct ListCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    init(
        icon: String,
        title: String,
        count: Int,
        color: Color,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.count = count
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // アイコンエリア（正方形）
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        ZStack {
                            Image(systemName: icon)
                                .font(.system(size: 40))
                                .foregroundColor(color)

                            // 選択時のチェックマーク
                            if isSelected {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.purple)
                                            .background(
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 24, height: 24)
                                            )
                                            .padding(8)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )

                // タイトルと件数
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("\(count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
