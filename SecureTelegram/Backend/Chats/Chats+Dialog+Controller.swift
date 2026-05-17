//
//  Chats+Dialog+Controller.swift
//  SecureTelegram
//
//  Created by Codex on 12.05.2026.
//

import Foundation
import Swinject

extension Chats.Dialog {

    struct Controller {

        protocol Interface {

            func fetchMessageHistory(
                chatID: Int64,
                fromMessageID: Int64,
                limit: Int
            ) async throws -> [Chats.Dialog.Message]

            func sendMessage(
                chatID: Int64,
                text: String,
                imageAttachments: [Chats.Dialog.Attachment]
            ) async throws

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                let resolver = container.synchronize()

                container.register(Interface.self) { _ in
                    Impl(resolver: resolver)
                }
                .inObjectScope(.container)
            }

        } // Factory

    } // Controller

} // Chats.Dialog
