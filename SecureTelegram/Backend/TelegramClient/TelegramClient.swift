//
//  TelegramClient.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

struct TelegramClient {

    struct Factory {

        static func register(with container: Container) {

            TelegramClient.Bridge.Factory.register(with: container)
            TelegramClient.Controller.Factory.register(with: container)
        }

    } // Factory

    enum Error: LocalizedError, Equatable {

        case missingAppConfiguration
        case invalidState
        case nativeBridgeNotConfigured
        case unauthorized

        var errorDescription: String? {

            switch self {
            case .missingAppConfiguration:
                return "Telegram app configuration is missing."
            case .invalidState:
                return "Telegram client state is invalid."
            case .nativeBridgeNotConfigured:
                return "TDLib native bridge is not configured yet."
            case .unauthorized:
                return "Telegram session is no longer authorized."
            }
        }

    } // Error

    struct Parameters: Equatable {

        let apiID: Int
        let apiHash: String
        let databaseDirectory: String
        let filesDirectory: String
        let databaseEncryptionKey: Data
        let useTestDataCenter: Bool
        let useFileDatabase: Bool
        let useChatInfoDatabase: Bool
        let useMessageDatabase: Bool
        let useSecretChats: Bool
        let systemLanguageCode: String
        let deviceModel: String
        let systemVersion: String
        let applicationVersion: String

    } // Parameters

    enum AuthorizationState: Equatable {

        case waitTdlibParameters
        case waitPhoneNumber
        case waitCode(phoneNumber: String?)
        case waitPassword
        case ready(User?)
        case loggingOut
        case closed
        case unknown(String)

    } // AuthorizationState

    struct User: Codable, Equatable {

        let id: Int64
        let firstName: String?
        let lastName: String?
        let username: String?
        let phoneNumber: String?

    } // User

} // TelegramClient
