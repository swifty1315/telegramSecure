//
//  Authorization+Controller+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import OSLog
import Swinject

extension Authorization.Controller {

    final class Impl: Interface {

        init(resolver: Resolver) {

            self.telegramClient = resolver.resolve(TelegramClient.Controller.Interface.self)!
            self.authStateStorage = resolver.resolve(Storage.AuthState.Interface.self)!
        }

        var state: Authorization.State {

            currentState
        }

        func initialize() async throws -> Authorization.State {

            logger.info("*** AUTH initialize started.")
            let state = try await telegramClient.initialize()
            let mappedState = try consume(state)
            logger.info("*** AUTH initialize finished with state: \(self.describe(mappedState), privacy: .public).")

            return mappedState
        }

        func sendCode(to phoneNumber: String) async throws -> Authorization.State {

            let sanitizedPhoneNumber = sanitize(phoneNumber)
            logger.info("*** AUTH sendCode requested for phone: \(self.mask(phoneNumber: sanitizedPhoneNumber), privacy: .public).")

            guard isValid(phoneNumber: sanitizedPhoneNumber) else {
                logger.error("*** AUTH sendCode rejected. Invalid phone number.")
                throw Authorization.Error.invalidPhoneNumber
            }

            let state = try await telegramClient.setAuthenticationPhoneNumber(sanitizedPhoneNumber)
            let mappedState = try consume(state)
            logger.info("*** AUTH sendCode finished with state: \(self.describe(mappedState), privacy: .public).")

            return mappedState
        }

        func confirmCode(_ code: String) async throws -> Authorization.State {

            let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("*** AUTH confirmCode requested. codeLength=\(normalizedCode.count, privacy: .public).")

            guard normalizedCode.isEmpty == false else {
                logger.error("*** AUTH confirmCode rejected. Code is empty.")
                throw Authorization.Error.invalidCode
            }

            let state = try await telegramClient.checkAuthenticationCode(normalizedCode)
            let mappedState = try consume(state)
            logger.info("*** AUTH confirmCode finished with state: \(self.describe(mappedState), privacy: .public).")

            return mappedState
        }

        func confirmPassword(_ password: String) async throws -> Authorization.State {

            let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("*** AUTH confirmPassword requested. passwordLength=\(normalizedPassword.count, privacy: .public).")

            guard normalizedPassword.isEmpty == false else {
                logger.error("*** AUTH confirmPassword rejected. Password is empty.")
                throw Authorization.Error.invalidPassword
            }

            let state = try await telegramClient.checkAuthenticationPassword(normalizedPassword)
            let mappedState = try consume(state)
            logger.info("*** AUTH confirmPassword finished with state: \(self.describe(mappedState), privacy: .public).")

            return mappedState
        }

        private let telegramClient: any TelegramClient.Controller.Interface
        private let authStateStorage: Storage.AuthState.Interface
        private let logger = Logger.authorization

        private var currentState: Authorization.State = .waitPhoneNumber

        private func consume(_ state: TelegramClient.AuthorizationState) throws -> Authorization.State {

            let mappedState: Authorization.State

            switch state {
            case .waitPhoneNumber:
                mappedState = .waitPhoneNumber

            case .waitTdlibParameters:
                logger.error("*** AUTH consume received unexpected waitTdlibParameters state.")
                throw Authorization.Error.invalidState

            case .waitCode(let phoneNumber):
                if let phoneNumber {
                    authStateStorage.savePendingContext(
                        .init(
                            phoneNumber: phoneNumber,
                            phoneCodeHash: ""
                        )
                    )
                }

                mappedState = .waitCode(phoneNumber: phoneNumber)

            case .waitPassword:
                mappedState = .waitPassword

            case .ready(let user):
                guard let user else {
                    logger.error("*** AUTH consume received ready state without user payload.")
                    throw Authorization.Error.invalidState
                }

                let session = Authorization.Session(
                    user: .init(
                        id: user.id,
                        firstName: user.firstName,
                        lastName: user.lastName,
                        username: user.username,
                        phoneNumber: user.phoneNumber
                    )
                )

                authStateStorage.clearPendingContext()
                authStateStorage.saveSession(
                    .init(
                        accessToken: "tdlib-local-session",
                        refreshToken: nil,
                        userID: user.id
                    )
                )

                mappedState = .ready(session)

            case .loggingOut:
                authStateStorage.clearSession()
                mappedState = .loggingOut

            case .closed:
                mappedState = .closed

            case .unknown:
                throw Authorization.Error.invalidState
            }

            currentState = mappedState

            return mappedState
        }

        private func mask(phoneNumber: String) -> String {

            guard phoneNumber.count > 4 else {
                return phoneNumber
            }

            let suffix = phoneNumber.suffix(4)

            return "***\(suffix)"
        }

        private func describe(_ state: Authorization.State) -> String {

            switch state {
            case .waitPhoneNumber:
                return "waitPhoneNumber"
            case .waitCode(let phoneNumber):
                return "waitCode(phone: \(mask(phoneNumber: phoneNumber ?? "")))"
            case .waitPassword:
                return "waitPassword"
            case .ready(let session):
                return "ready(userID: \(session.user.id))"
            case .loggingOut:
                return "loggingOut"
            case .closed:
                return "closed"
            }
        }

        private func sanitize(_ phoneNumber: String) -> String {

            phoneNumber
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .filter { $0.isNumber || $0 == "+" }
        }

        private func isValid(phoneNumber: String) -> Bool {

            phoneNumber.hasPrefix("+") && phoneNumber.count >= 8
        }

    } // Impl

} // Authorization.Controller
