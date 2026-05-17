//
//  Chats+List+Controller.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Chats.List {

    struct Controller {

        protocol Interface {

            func fetchDialogs(limit: Int) async throws -> [Chats.List.Item]

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

} // Chats.List
