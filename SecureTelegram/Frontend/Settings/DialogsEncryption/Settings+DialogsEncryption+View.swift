//
//  Settings+DialogsEncryption+View.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import SwiftUI

extension Settings.DialogsEncryption {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Settings.DialogsEncryption.ViewModel.Impl

        var body: some SwiftUI.View {

            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                    errorView(message: errorMessage)
                } else {
                    listView
                }
            }
            .task {
                viewModel.onAppear()
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }

        private var loadingView: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.subtitle)
                    .font(.body)
                    .foregroundStyle(Color.secondaryText)

                ProgressView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }

        private func errorView(message: String) -> some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.subtitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.text)

                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }

        private var listView: some SwiftUI.View {

            List {
                Section {
                    ForEach(viewModel.items) { item in
                        row(item: item)
                            .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                } header: {
                    Text(viewModel.subtitle)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.refresh()
            }
        }

        private func row(item: Chats.List.Item) -> some SwiftUI.View {

            HStack(spacing: 12) {
                avatar(for: item)

                Text(item.title.isEmpty ? "Unknown Chat" : item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.text)
                    .lineLimit(1)

                Spacer(minLength: 8)
            }
            .contentShape(Rectangle())
        }

        private func avatar(for item: Chats.List.Item) -> some SwiftUI.View {

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.registrationGradient1,
                                Color.registrationGradient2,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(initials(for: item.title))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Controls.AsyncImage.View(
                    viewModel: .init(localPath: item.avatarLocalPath)
                )
                .clipShape(Circle())
            }
            .frame(width: 44, height: 44)
        }

        private func initials(for title: String) -> String {

            let components = title
                .split(separator: " ")
                .prefix(2)
                .compactMap { $0.first }

            let initials = String(components)

            if initials.isEmpty {
                return "TG"
            }

            return initials.uppercased()
        }

    } // View

} // Settings.DialogsEncryption
