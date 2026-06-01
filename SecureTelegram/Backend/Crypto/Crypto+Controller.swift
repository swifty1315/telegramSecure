//
//  Crypto+Controller.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import Swinject

extension Crypto {

    struct Controller {

        enum Action {

            case encrypt
            case decrypt

        } // Action

        protocol Interface {

            func perform(
                algorithm: String,
                key: String,
                message: String,
                action: Action
            ) throws -> String

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                container.register(Interface.self) { _ in
                    Impl()
                }
                .inObjectScope(.container)
            }

        } // Factory

    } // Controller

} // Crypto
