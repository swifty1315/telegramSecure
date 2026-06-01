//
//  Storage.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

struct Storage {

    struct Factory {

        static func register(with container: Container) {

            Storage.Defaults.Factory.register(with: container)
            Storage.Keychain.Factory.register(with: container)
            Storage.Secure.Factory.register(with: container)
            Storage.AuthState.Factory.register(with: container)
            Storage.TelegramRuntime.Factory.register(with: container)
        }

    } // Factory

    struct Auth {

        struct PendingContext: Codable, Equatable {

            let phoneNumber: String
            let phoneCodeHash: String

        } // PendingContext

        struct Session: Codable, Equatable {

            let accessToken: String
            let refreshToken: String?
            let userID: Int64

            enum CodingKeys: String, CodingKey {

                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case userID = "user_id"
            }

        } // Session

    } // Auth

} // Storage
