//
//  TelegramClient+Controller+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(OSLog)
import OSLog
#endif
#if canImport(TDLibKit)
import TDLibKit
#endif
import Swinject

extension TelegramClient.Controller {

    final class Impl: Interface {

        init(resolver: Resolver) {

            self.bridge = resolver.resolve(TelegramClient.Bridge.Interface.self)!
            self.runtimeStorage = resolver.resolve(Storage.TelegramRuntime.Interface.self)!
        }

        var authorizationState: TelegramClient.AuthorizationState {

            bridge.authorizationState
        }

        func initialize() async throws -> TelegramClient.AuthorizationState {

            logger.info("*** TDLIB initialize started.")
            try runtimeStorage.prepare()

            do {
                let parameters = try makeParameters()
                logger.debug("*** TDLIB initialize with databasePath=\(parameters.databaseDirectory, privacy: .public) filesPath=\(parameters.filesDirectory, privacy: .public).")

                let state = try await bridge.initialize(with: parameters)
                logger.info("*** TDLIB initialize finished with state: \(self.describe(state), privacy: .public).")

                return state
            } catch {
                logger.error("*** TDLIB initialize failed: \(self.makeErrorMessage(from: error), privacy: .public).")

                guard shouldResetRuntimeStorage(after: error) else {
                    throw error
                }

                logger.warning("*** TDLIB initialize will reset runtime storage and retry.")
                await bridge.reset()
                try runtimeStorage.reset()

                let parameters = try makeParameters()
                logger.debug("*** TDLIB initialize retry with databasePath=\(parameters.databaseDirectory, privacy: .public) filesPath=\(parameters.filesDirectory, privacy: .public).")

                let state = try await bridge.initialize(with: parameters)
                logger.info("*** TDLIB initialize retry finished with state: \(self.describe(state), privacy: .public).")

                return state
            }
        }

        func setAuthenticationPhoneNumber(_ phoneNumber: String) async throws -> TelegramClient.AuthorizationState {

            try await ensureReadyForPhoneNumberInput()
            logger.info("*** TDLIB setAuthenticationPhoneNumber for phone: \(self.mask(phoneNumber: phoneNumber), privacy: .public). currentState=\(self.describe(self.authorizationState), privacy: .public).")

            let state = try await bridge.setAuthenticationPhoneNumber(phoneNumber)
            logger.info("*** TDLIB setAuthenticationPhoneNumber finished with state: \(self.describe(state), privacy: .public).")

            return state
        }

        func checkAuthenticationCode(_ code: String) async throws -> TelegramClient.AuthorizationState {

            logger.info("*** TDLIB checkAuthenticationCode. codeLength=\(code.count, privacy: .public) currentState=\(self.describe(self.authorizationState), privacy: .public).")

            let state = try await bridge.checkAuthenticationCode(code)
            logger.info("*** TDLIB checkAuthenticationCode finished with state: \(self.describe(state), privacy: .public).")

            return state
        }

        func checkAuthenticationPassword(_ password: String) async throws -> TelegramClient.AuthorizationState {

            logger.info("*** TDLIB checkAuthenticationPassword. passwordLength=\(password.count, privacy: .public) currentState=\(self.describe(self.authorizationState), privacy: .public).")

            let state = try await bridge.checkAuthenticationPassword(password)
            logger.info("*** TDLIB checkAuthenticationPassword finished with state: \(self.describe(state), privacy: .public).")

            return state
        }

        func fetchDialogs(limit: Int) async throws -> [Chats.List.Item] {

            try await bridge.fetchDialogs(limit: limit)
        }

        func fetchMessageHistory(
            chatID: Int64,
            fromMessageID: Int64,
            limit: Int
        ) async throws -> [Chats.Dialog.Message] {

            try await bridge.fetchMessageHistory(
                chatID: chatID,
                fromMessageID: fromMessageID,
                limit: limit
            )
        }

        func messageEvents(chatID: Int64) -> AsyncStream<Chats.Dialog.Event> {

            bridge.messageEvents(chatID: chatID)
        }

        func sendMessage(
            chatID: Int64,
            text: String,
            imageAttachments: [Chats.Dialog.Attachment]
        ) async throws {

            try await bridge.sendMessage(
                chatID: chatID,
                text: text,
                imageAttachments: imageAttachments
            )
        }

        private let bridge: any TelegramClient.Bridge.Interface
        private let runtimeStorage: Storage.TelegramRuntime.Interface
        private let logger = Logger.telegramClient

        private func ensureReadyForPhoneNumberInput() async throws {

            switch self.authorizationState {
            case .waitTdlibParameters, .closed:
                logger.warning("*** TDLIB setAuthenticationPhoneNumber requested before TDLib reached waitPhoneNumber. Forcing initialize.")
                _ = try await initialize()
            default:
                break
            }
        }

        private func shouldResetRuntimeStorage(after error: Swift.Error) -> Bool {

            if let error = error as? Storage.TelegramRuntime.Error {
                switch error {
                case .missingDatabaseEncryptionKey:
                    return true
                }
            }

#if canImport(TDLibKit)
            guard let error = error as? TDLibKit.Error else {
                return false
            }

            return error.message.localizedCaseInsensitiveContains("wrong database encryption key")
                || error.message.localizedCaseInsensitiveContains("database is corrupted")
#else
            return false
#endif
        }

        private func makeErrorMessage(from error: Swift.Error) -> String {

#if canImport(TDLibKit)
            if let error = error as? TDLibKit.Error {
                return "[code=\(error.code)] \(error.message)"
            }
#endif

            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               description.isEmpty == false {
                return description
            }

            return error.localizedDescription
        }

        private func mask(phoneNumber: String) -> String {

            guard phoneNumber.count > 4 else {
                return phoneNumber
            }

            return "***\(phoneNumber.suffix(4))"
        }

        private func describe(_ state: TelegramClient.AuthorizationState) -> String {

            switch state {
            case .waitTdlibParameters:
                return "waitTdlibParameters"
            case .waitPhoneNumber:
                return "waitPhoneNumber"
            case .waitCode(let phoneNumber):
                return "waitCode(phone: \(mask(phoneNumber: phoneNumber ?? "")))"
            case .waitPassword:
                return "waitPassword"
            case .ready(let user):
                return "ready(userID: \(user?.id ?? 0))"
            case .loggingOut:
                return "loggingOut"
            case .closed:
                return "closed"
            case .unknown(let value):
                return "unknown(\(value))"
            }
        }

        private func makeParameters() throws -> TelegramClient.Parameters {

            guard let apiID = AppConfiguration.Telegram.apiID,
                  let apiHash = AppConfiguration.Telegram.apiHash,
                  apiHash.isEmpty == false else {
                throw TelegramClient.Error.missingAppConfiguration
            }

            return TelegramClient.Parameters(
                apiID: apiID,
                apiHash: apiHash,
                databaseDirectory: runtimeStorage.databaseURL.path(percentEncoded: false),
                filesDirectory: runtimeStorage.filesURL.path(percentEncoded: false),
                databaseEncryptionKey: runtimeStorage.databaseEncryptionKey,
                useTestDataCenter: AppConfiguration.Telegram.useTestDataCenter,
                useFileDatabase: AppConfiguration.Telegram.useFileDatabase,
                useChatInfoDatabase: AppConfiguration.Telegram.useChatInfoDatabase,
                useMessageDatabase: AppConfiguration.Telegram.useMessageDatabase,
                useSecretChats: AppConfiguration.Telegram.useSecretChats,
                systemLanguageCode: AppConfiguration.Telegram.systemLanguageCode,
                deviceModel: AppConfiguration.Telegram.deviceModel,
                systemVersion: AppConfiguration.Telegram.systemVersion,
                applicationVersion: AppConfiguration.Telegram.applicationVersion
            )
        }

    } // Impl

} // TelegramClient.Controller
