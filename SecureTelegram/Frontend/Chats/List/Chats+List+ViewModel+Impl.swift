//
//  Chats+List+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine
import Swinject
import OSLog

extension Chats.List.ViewModel {

    @MainActor
    final class Impl: Interface {

        enum Action: Equatable {

            case openDialog

        } // Action

        init(resolver: Resolver) {

            self.controller = resolver.resolve(Chats.List.Controller.Interface.self)!
            self.dialogViewModel = resolver.resolve(Chats.Dialog.ViewModel.Impl.self)!
        }

        @Published var action: Action?
        @Published private(set) var items: [Chats.List.Item] = []
        @Published private(set) var isLoading = false
        @Published private(set) var errorMessage: String?
        @Published private(set) var hasAuthorizationExpired = false

        let dialogViewModel: Chats.Dialog.ViewModel.Impl

        var navigationTitle: String {

            "Dialogs"
        }

        var title: String {

            "Your dialogs"
        }

        var subtitle: String {

            "Recent Telegram conversations, fetched directly from TDLib."
        }

        var emptyTitle: String {

            "No dialogs yet"
        }

        var emptyMessage: String {

            "When TDLib loads your chats, they will appear here."
        }

        func onAppear() {

            guard didLoad == false else {
                return
            }

            didLoad = true
            refresh()
        }

        func refresh() {

            guard isLoading == false else {
                return
            }

            Task {
                await fetchDialogs()
            }
        }

        func didTapDialog(_ item: Chats.List.Item) {

            dialogViewModel.configure(
                chatID: item.id,
                title: item.title,
                avatarLocalPath: item.avatarLocalPath
            )
            action = .openDialog
        }

        func consumeAction() {

            action = nil
        }

        private let controller: any Chats.List.Controller.Interface
        private let logger = Logger.chats
        private var didLoad = false

        private func fetchDialogs() async {

            isLoading = true
            errorMessage = nil
            hasAuthorizationExpired = false
            defer { isLoading = false }

            do {
                logger.info("*** CHATS list fetch started.")
                items = try await controller.fetchDialogs(limit: 50)
                logger.info("*** CHATS list fetch finished. count=\(self.items.count, privacy: .public).")
            } catch {
                logger.error("*** CHATS list fetch failed: \(self.makeErrorMessage(from: error), privacy: .public).")
                if let error = error as? TelegramClient.Error,
                   error == .unauthorized {
                    logger.warning("*** CHATS list session expired. Returning to authorization flow.")
                    items = []
                    errorMessage = nil
                    hasAuthorizationExpired = true
                    return
                }

                errorMessage = makeErrorMessage(from: error)
            }
        }

        private func makeErrorMessage(from error: Swift.Error) -> String {

            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               description.isEmpty == false {
                return description
            }

            return error.localizedDescription
        }

    } // Impl

} // Chats.List.ViewModel
