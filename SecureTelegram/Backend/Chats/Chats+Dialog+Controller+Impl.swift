//
//  Chats+Dialog+Controller+Impl.swift
//  SecureTelegram
//
//  Created by Codex on 12.05.2026.
//

import Foundation
import Swinject

extension Chats.Dialog.Controller {

    final class Impl: Interface {

        init(resolver: Resolver) {

            self.telegramClient = resolver.resolve(TelegramClient.Controller.Interface.self)!
            self.secureStorage = resolver.resolve(Storage.Secure.Interface.self)!
            self.cryptoController = resolver.resolve(Crypto.Controller.Interface.self)!
        }

        func fetchMessageHistory(
            chatID: Int64,
            fromMessageID: Int64,
            limit: Int
        ) async throws -> [Chats.Dialog.Message] {

            let messages = try await telegramClient.fetchMessageHistory(
                chatID: chatID,
                fromMessageID: fromMessageID,
                limit: limit
            )

            return messages.map { decryptMessageIfNeeded($0) }
        }

        func messageEvents(chatID: Int64) -> AsyncStream<Chats.Dialog.Event> {

            let events = telegramClient.messageEvents(chatID: chatID)

            return AsyncStream { continuation in
                let task = Task { [weak self] in
                    for await event in events {
                        guard let self else {
                            continuation.yield(event)
                            continue
                        }

                        continuation.yield(self.decryptEventIfNeeded(event))
                    }

                    continuation.finish()
                }

                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        }

        func sendMessage(
            chatID: Int64,
            text: String,
            imageAttachments: [Chats.Dialog.Attachment]
        ) async throws {

            let preparedText = encryptTextIfNeeded(
                chatID: chatID,
                text: text,
                date: Date()
            )

            try await telegramClient.sendMessage(
                chatID: chatID,
                text: preparedText,
                imageAttachments: imageAttachments
            )
        }

        private let telegramClient: any TelegramClient.Controller.Interface
        private let secureStorage: Storage.Secure.Interface
        private let cryptoController: Crypto.Controller.Interface

        private func decryptEventIfNeeded(_ event: Chats.Dialog.Event) -> Chats.Dialog.Event {

            switch event {
            case .messageInserted(let message):
                return .messageInserted(decryptMessageIfNeeded(message))

            case .messageUpdated(let message):
                return .messageUpdated(decryptMessageIfNeeded(message))

            case .messagesDeleted, .refreshRequired:
                return event
            }
        }

        private func encryptTextIfNeeded(
            chatID: Int64,
            text: String,
            date: Date
        ) -> String {

            guard text.isEmpty == false,
                  let key = encryptionKey(for: chatID, at: date) else {
                return text
            }

            return (try? cryptoController.perform(
                algorithm: key.encryptionType,
                key: key.key,
                message: text,
                action: .encrypt
            )) ?? text
        }

        private func decryptMessageIfNeeded(_ message: Chats.Dialog.Message) -> Chats.Dialog.Message {

            guard message.text.isEmpty == false,
                  let key = encryptionKey(
                    for: message.chatID,
                    at: Date(timeIntervalSince1970: TimeInterval(message.sentAt))
                  ) else {
                return message
            }

            let decryptedText = (try? cryptoController.perform(
                algorithm: key.encryptionType,
                key: key.key,
                message: message.text,
                action: .decrypt
            )) ?? message.text

            guard decryptedText != message.text else {
                return message
            }

            return message.withText(decryptedText)
        }

        private func encryptionKey(
            for chatID: Int64,
            at date: Date
        ) -> Storage.Secure.DecryptedDialogEncryptionKey? {

            guard let keys = try? secureStorage.dialogEncryptionKeys(for: chatID) else {
                return nil
            }

            return keys.last { key in
                guard key.appliedFrom <= date else {
                    return false
                }

                if let appliedTo = key.appliedTo {
                    return date < appliedTo
                }

                return true
            }
        }

    } // Impl

} // Chats.Dialog.Controller

private extension Chats.Dialog.Message {

    func withText(_ text: String) -> Chats.Dialog.Message {

        .init(
            id: id,
            chatID: chatID,
            text: text,
            imageLocalPath: imageLocalPath,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            sentAt: sentAt,
            isOutgoing: isOutgoing
        )
    }

} // Chats.Dialog.Message
