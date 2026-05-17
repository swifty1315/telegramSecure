//
//  TelegramClient+Controller.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension TelegramClient {

    struct Controller {

        protocol Interface {

            var authorizationState: TelegramClient.AuthorizationState { get }

            func initialize() async throws -> TelegramClient.AuthorizationState

            func setAuthenticationPhoneNumber(_ phoneNumber: String) async throws -> TelegramClient.AuthorizationState

            func checkAuthenticationCode(_ code: String) async throws -> TelegramClient.AuthorizationState

            func checkAuthenticationPassword(_ password: String) async throws -> TelegramClient.AuthorizationState

            func fetchDialogs(limit: Int) async throws -> [Chats.List.Item]

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

} // TelegramClient
