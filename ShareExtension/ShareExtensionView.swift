//
//  ShareExtensionView.swift
//  ShareExtension
//
//  Share Extension UI (処理はShareViewControllerで実行)
//

import SwiftUI

struct ShareExtensionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text("Obiで開いています...")
                .font(.headline)

            ProgressView()
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ShareExtensionView()
}
