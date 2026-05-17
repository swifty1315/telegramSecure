//
//  Authorization.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

struct Authorization {

    struct Factory {

        static func register(with container: Container) {

            Authorization.Controller.Factory.register(with: container)
            Authorization.ViewModel.Factory.register(with: container)
        }

    } // Factory

    enum Error: LocalizedError, Equatable {

        case invalidPhoneNumber
        case invalidCode
        case invalidPassword
        case missingTelegramAppConfiguration
        case invalidState
        case telegramClientUnavailable

        var errorDescription: String? {

            switch self {
            case .invalidPhoneNumber:
                return "Phone number is invalid."
            case .invalidCode:
                return "Code is invalid."
            case .invalidPassword:
                return "Password is invalid."
            case .missingTelegramAppConfiguration:
                return "Telegram application configuration is missing."
            case .invalidState:
                return "Authorization is in invalid state."
            case .telegramClientUnavailable:
                return "Telegram client is unavailable."
            }
        }

    } // Error

    enum State: Equatable {

        case waitPhoneNumber
        case waitCode(phoneNumber: String?)
        case waitPassword
        case ready(Session)
        case loggingOut
        case closed

    } // State

    struct Session: Equatable {

        let user: Authorization.User

    } // Session

    struct User: Codable, Equatable {

        let id: Int64
        let firstName: String?
        let lastName: String?
        let username: String?
        let phoneNumber: String?

        enum CodingKeys: String, CodingKey {

            case id
            case firstName = "first_name"
            case lastName = "last_name"
            case username
            case phoneNumber = "phone_number"
        }

    } // User

} // Authorization
