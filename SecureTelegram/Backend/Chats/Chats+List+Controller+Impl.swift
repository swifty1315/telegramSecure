//
//  Chats+List+Controller+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Chats.List.Controller {

    final class Impl: Interface {

        init(resolver: Resolver) {

            self.telegramClient = resolver.resolve(TelegramClient.Controller.Interface.self)!
        }

        func fetchDialogs(limit: Int) async throws -> [Chats.List.Item] {

            try await telegramClient.fetchDialogs(limit: limit)
        }

        private let telegramClient: any TelegramClient.Controller.Interface

    } // Impl

} // Chats.List.Controller
