//
//  Storage+Defaults.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Storage {

    struct Defaults {

        protocol Interface {

            func setObject<T: Codable>(_ value: T, for key: String)

            func getObject<T: Codable>(_ key: String, type: T.Type) -> T?

            func removeValue(for key: String)

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                container.register(Interface.self) { _ in
                    Impl()
                }
                .inObjectScope(.container)
            }

        } // Factory

        struct Key {

            static let pendingAuthorization = "storage.pendingAuthorization"

        } // Key

        final class Impl: Interface {

            init(userDefaults: UserDefaults = .standard) {

                self.userDefaults = userDefaults
            }

            func setObject<T: Codable>(_ value: T, for key: String) {

                guard let data = try? encoder.encode(value) else {
                    return
                }

                userDefaults.set(data, forKey: key)
            }

            func getObject<T: Codable>(_ key: String, type: T.Type) -> T? {

                guard let data = userDefaults.data(forKey: key) else {
                    return nil
                }

                return try? decoder.decode(type, from: data)
            }

            func removeValue(for key: String) {

                userDefaults.removeObject(forKey: key)
            }

            private let userDefaults: UserDefaults
            private let encoder = JSONEncoder()
            private let decoder = JSONDecoder()

        } // Impl

    } // Defaults

} // Storage
