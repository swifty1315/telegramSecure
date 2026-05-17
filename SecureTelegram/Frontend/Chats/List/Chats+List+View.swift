//
//  Chats+List+View.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI
import Combine

extension Chats.List {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Chats.List.ViewModel.Impl
        @StateObject private var router = Chats.List.Router()

        var body: some SwiftUI.View {

            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                    errorView(message: errorMessage)
                } else if viewModel.items.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .task {
                viewModel.onAppear()
            }
            .onReceive(viewModel.$action.compactMap { $0 }) { action in
                switch action {
                case .openDialog:
                    router.route = .dialog
                }

                viewModel.consumeAction()
            }
            .navigationDestination(item: $router.route) { route in
                switch route {
                case .dialog:
                    Chats.Dialog.View(viewModel: viewModel.dialogViewModel)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.large)
        }

        private var loadingView: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.title)

                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(viewModel.subtitle)

                    .font(.body)
                    .foregroundStyle(Color.secondaryText)

                ProgressView()
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }

        private var emptyView: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.emptyTitle)

                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(viewModel.emptyMessage)

                    .font(.body)
                    .foregroundStyle(Color.secondaryText)
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }

        private func errorView(message: String) -> some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text("Failed to load dialogs")

                    .font(.system(size: 28, weight: .bold, design: .rounded))
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
                            .listRowSeparator(.hidden)
                    }
                }

//                Section {
//
//                    
//
//                } header: {
//
//                    VStack(alignment: .leading, spacing: 8) {
//
//                        Text(viewModel.title)
//
//                            .font(.system(size: 28, weight: .bold, design: .rounded))
//                            .foregroundStyle(Color.text)
//
//                        Text(viewModel.subtitle)
//
//                            .font(.body)
//                            .foregroundStyle(Color.secondaryText)
//                    }
//                    .textCase(nil)
//                    .padding(.bottom, 8)
//                }
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.refresh()
            }
        }

        private func row(item: Chats.List.Item) -> some SwiftUI.View {

            Button {
                viewModel.didTapDialog(item)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    avatar(for: item)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(item.title.isEmpty ? "Unknown Chat" : item.title)

                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.text)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text(formattedTime(for: item.lastMessageDate))

                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.secondaryText)
                        }

                        HStack(alignment: .center, spacing: 8) {
                            Text(item.preview.isEmpty ? "No messages yet" : item.preview)

                                .font(.system(size: 15))
                                .foregroundStyle(Color.secondaryText)
                                .lineLimit(2)

                            Spacer(minLength: 8)

                            if item.unreadCount > 0 {
                                unreadBadge(count: item.unreadCount)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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

            .frame(width: 52, height: 52)
        }

        private func unreadBadge(count: Int) -> some SwiftUI.View {

            Text("\(count)")

                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.appSuccess, in: Capsule())
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

        private func formattedTime(for timestamp: Int) -> String {

            guard timestamp > 0 else {
                return ""
            }

            return Self.timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
        }

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter
        }()

    } // View

} // Chats.List
