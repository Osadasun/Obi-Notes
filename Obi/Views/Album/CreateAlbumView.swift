//
//  CreateAlbumView.swift
//  Obi
//
//  ユーザーアルバム作成画面
//

import SwiftUI

struct CreateAlbumView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateAlbumViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("アルバム名")) {
                    TextField("アルバム名を入力", text: $viewModel.albumName)
                }

                Section(header: Text("カラー")) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.colorPresets, id: \.description) { color in
                            Button(action: {
                                viewModel.selectedColor = color
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 50, height: 50)

                                    if viewModel.selectedColor.toHex() == color.toHex() {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("アルバムを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        Task {
                            if await viewModel.createAlbum() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canCreate || viewModel.isCreating)
                }
            }
        }
    }
}

#Preview {
    CreateAlbumView()
}
