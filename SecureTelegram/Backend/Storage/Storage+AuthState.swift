//
//  Storage+AuthState.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Storage {

    struct AuthState {

        protocol Interface {

            var pendingContext: Storage.Auth.PendingContext? { get }

            var session: Storage.Auth.Session? { get }

            func savePendingContext(_ context: Storage.Auth.PendingContext)

            func clearPendingContext()

            func saveSession(_ session: Storage.Auth.Session)

            func clearSession()

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

        final class Impl: Interface {

            init(resolver: Resolver) {

                self.defaults = resolver.resolve(Storage.Defaults.Interface.self)!
                self.keychain = resolver.resolve(Storage.Keychain.Interface.self)!
            }

            var pendingContext: Storage.Auth.PendingContext? {

                defaults.getObject(
                    Storage.Defaults.Key.pendingAuthorization,
                    type: Storage.Auth.PendingContext.self
                )
            }

            var session: Storage.Auth.Session? {

                guard let data = keychain.data(for: Storage.Keychain.Key.authorizationSession) else {
                    return nil
                }

                return try? decoder.decode(Storage.Auth.Session.self, from: data)
            }

            func savePendingContext(_ context: Storage.Auth.PendingContext) {

                defaults.setObject(context, for: Storage.Defaults.Key.pendingAuthorization)
            }

            func clearPendingContext() {

                defaults.removeValue(for: Storage.Defaults.Key.pendingAuthorization)
            }

            func saveSession(_ session: Storage.Auth.Session) {

                guard let data = try? encoder.encode(session) else {
                    return
                }

                keychain.setData(data, for: Storage.Keychain.Key.authorizationSession)
            }

            func clearSession() {

                keychain.removeValue(for: Storage.Keychain.Key.authorizationSession)
            }

            private let defaults: Storage.Defaults.Interface
            private let keychain: Storage.Keychain.Interface
            private let encoder = JSONEncoder()
            private let decoder = JSONDecoder()

        } // Impl

    } // AuthState

} // Storage
