//
//  Chats+Dialog+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine
import Swinject

extension Chats.Dialog.ViewModel {

    @MainActor
    final class Impl: Interface {

        init(resolver: Resolver) {

            self.controller = resolver.resolve(Chats.Dialog.Controller.Interface.self)!
            self.composerViewModel = resolver.resolve(Chats.Dialog.Composer.ViewModel.Impl.self)!
        }

        @Published private(set) var messages: [Chats.Dialog.Message] = []
        @Published private(set) var isLoading = false
        @Published private(set) var errorMessage: String?

        let composerViewModel: Chats.Dialog.Composer.ViewModel.Impl

        var navigationTitle: String {

            dialogTitle.isEmpty ? "Dialog" : dialogTitle
        }

        var title: String {

            dialogTitle.isEmpty ? "Dialog History" : dialogTitle
        }

        var subtitle: String {

            "Recent messages from the selected Telegram dialog."
        }

        var avatarLocalPath: String? {

            dialogAvatarLocalPath
        }

        var emptyTitle: String {

            "No messages yet"
        }

        var emptyMessage: String {

            "When TDLib returns history for this dialog, it will appear here."
        }

        func configure(
            chatID: Int64,
            title: String,
            avatarLocalPath: String?
        ) {

            let hasChanged = self.chatID != chatID

            self.chatID = chatID
            self.dialogTitle = title
            self.dialogAvatarLocalPath = avatarLocalPath
            self.composerViewModel.configure(chatID: chatID)

            if hasChanged {
                messages = []
                errorMessage = nil
                didLoad = false
            }
        }

        func onAppear() {

            guard didLoad == false else {
                return
            }

            didLoad = true
            refresh()
        }

        func refresh() {

            guard chatID != 0 else {
                return
            }

            guard isLoading == false else {
                return
            }

            Task {
                await fetchMessageHistory()
            }
        }

        private let controller: any Chats.Dialog.Controller.Interface
        private var chatID: Int64 = 0
        private var dialogTitle = ""
        private var dialogAvatarLocalPath: String?
        private var didLoad = false

        private func fetchMessageHistory() async {

            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                messages = try await controller.fetchMessageHistory(
                    chatID: chatID,
                    fromMessageID: 0,
                    limit: 30
                )
            } catch {
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

} // Chats.Dialog.ViewModel
