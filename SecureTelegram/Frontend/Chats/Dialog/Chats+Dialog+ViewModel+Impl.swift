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

        var messageSections: [Chats.Dialog.ViewModel.MessageSection] {

            makeMessageSections(from: messages)
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
                stopMessageEvents()
            }
        }

        func onAppear() {

            startMessageEventsIfNeeded()

            guard didLoad == false else {
                return
            }

            didLoad = true
            refresh()
        }

        func onDisappear() {

            stopMessageEvents()
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
        private var messageEventsTask: Task<Void, Never>?
        private var messageEventsChatID: Int64?

        private func makeMessageSections(
            from messages: [Chats.Dialog.Message]
        ) -> [Chats.Dialog.ViewModel.MessageSection] {

            let calendar = Calendar.current
            let groupedMessages = Dictionary(grouping: messages) { message in
                calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(message.sentAt)))
            }

            return groupedMessages.keys
                .sorted()
                .map { day in
                    .init(
                        id: day,
                        day: day,
                        messages: groupedMessages[day, default: []].sorted { $0.id < $1.id }
                    )
                }
        }

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

        private func startMessageEventsIfNeeded() {

            guard chatID != 0 else {
                return
            }

            guard messageEventsChatID != chatID else {
                return
            }

            stopMessageEvents()

            let currentChatID = chatID
            messageEventsChatID = currentChatID
            messageEventsTask = Task { [weak self] in
                guard let self else {
                    return
                }

                let events = self.controller.messageEvents(chatID: currentChatID)

                for await event in events {
                    guard Task.isCancelled == false else {
                        return
                    }

                    self.handleMessageEvent(event, expectedChatID: currentChatID)
                }
            }
        }

        private func stopMessageEvents() {

            messageEventsTask?.cancel()
            messageEventsTask = nil
            messageEventsChatID = nil
        }

        private func handleMessageEvent(
            _ event: Chats.Dialog.Event,
            expectedChatID: Int64
        ) {

            guard chatID == expectedChatID else {
                return
            }

            switch event {
            case .messageInserted(let message):
                guard message.chatID == expectedChatID else {
                    return
                }

                upsert(message)

            case .messageUpdated(let message):
                guard message.chatID == expectedChatID else {
                    return
                }

                upsert(message)

            case .messagesDeleted(let chatID, let messageIDs):
                guard chatID == expectedChatID else {
                    return
                }

                messages.removeAll { messageIDs.contains($0.id) }

            case .refreshRequired(let chatID):
                guard chatID == expectedChatID else {
                    return
                }

                refresh()
            }
        }

        private func upsert(_ message: Chats.Dialog.Message) {

            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = message
            } else {
                messages.append(message)
            }

            messages.sort { $0.id < $1.id }
            errorMessage = nil
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
