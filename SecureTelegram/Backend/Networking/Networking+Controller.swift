//
//  Networking+Controller.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Networking {

    struct Controller {

        protocol Interface {

            var isNetworkConnectionPresent: Bool { get }

            func clearCache()

            func clearCache(for request: Networking.Request)

            func data(for url: URL) async throws -> Networking.Response

            func perform(_ request: Networking.Request) async throws -> Networking.Response

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

} // Networking
