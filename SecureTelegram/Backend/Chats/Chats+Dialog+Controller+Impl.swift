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
        }

        func fetchMessageHistory(
            chatID: Int64,
            fromMessageID: Int64,
            limit: Int
        ) async throws -> [Chats.Dialog.Message] {

            try await telegramClient.fetchMessageHistory(
                chatID: chatID,
                fromMessageID: fromMessageID,
                limit: limit
            )
        }

        func sendMessage(
            chatID: Int64,
            text: String,
            imageAttachments: [Chats.Dialog.Attachment]
        ) async throws {

            try await telegramClient.sendMessage(
                chatID: chatID,
                text: text,
                imageAttachments: imageAttachments
            )
        }

        private let telegramClient: any TelegramClient.Controller.Interface

    } // Impl

} // Chats.Dialog.Controller
