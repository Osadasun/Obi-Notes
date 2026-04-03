//
//  MoveToListView.swift
//  Obi
//
//  リスト/アルバム移動先選択画面
//

import SwiftUI

struct MoveToListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: MoveToListViewModel
    let onMoved: () -> Void

    init(sourceType: MoveToListViewModel.SourceType, obiListViewModel: ObiListViewModel? = nil, onMoved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: MoveToListViewModel(sourceType: sourceType, obiListViewModel: obiListViewModel))
        self.onMoved = onMoved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if viewModel.lists.isEmpty {
                        ContentUnavailableView(
                            "移動先がありません",
                            systemImage: "folder",
                            description: Text("先にカスタムリストを作成してください")
                        )
                        .padding(.top, 100)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            // ルート（親なし）オプション
                            Button(action: {
                                viewModel.selectedList = nil
                            }) {
                                HStack {
                                    Image(systemName: viewModel.selectedList == nil ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.selectedList == nil ? .purple : .gray)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ルート（トップレベル）")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)

                                        Text("Obiタブのトップに表示")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 24)

                            // カスタムリスト
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                                ForEach(viewModel.sortedLists) { list in
                                    Button(action: {
                                        viewModel.selectedList = list
                                    }) {
                                        ListCard(
                                            title: list.name,
                                            count: 0,
                                            artworkURLs: [],
                                            isSelected: viewModel.selectedList?.id == list.id,
                                            isPinned: viewModel.obiListViewModel?.isPinned(itemId: "list-\(list.id)") ?? false,
                                            isDefault: false
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("移動先を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isMoving {
                        ProgressView()
                    } else {
                        Button("移動") {
                            Task {
                                let success = await viewModel.moveToSelectedList()
                                if success {
                                    onMoved()
                                    dismiss()
                                }
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(viewModel.isMoving)
                    }
                }
            }
            .task {
                await viewModel.loadLists()
            }
        }
    }
}
