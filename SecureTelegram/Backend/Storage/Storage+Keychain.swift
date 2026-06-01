//
//  Storage+Keychain.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Security
import Swinject

extension Storage {

    struct Keychain {

        protocol Interface {

            func data(for key: String) -> Data?

            func setData(_ data: Data, for key: String)

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

            static let authorizationSession = "storage.authorizationSession"
            static let tdlibDatabaseEncryptionKey = "storage.tdlibDatabaseEncryptionKey"
            static let secureStorageMasterKey = "storage.secureStorageMasterKey"

        } // Key

        final class Impl: Interface {

            func data(for key: String) -> Data? {

                var query = makeBaseQuery(for: key)
                query[kSecReturnData as String] = true
                query[kSecMatchLimit as String] = kSecMatchLimitOne

                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)

                guard status == errSecSuccess else {
                    return nil
                }

                return result as? Data
            }

            func setData(_ data: Data, for key: String) {

                let query = makeBaseQuery(for: key)
                let attributes = [kSecValueData as String: data] as CFDictionary
                let status = SecItemUpdate(query as CFDictionary, attributes)

                guard status == errSecItemNotFound else {
                    return
                }

                var createQuery = query
                createQuery[kSecValueData as String] = data
                createQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

                SecItemAdd(createQuery as CFDictionary, nil)
            }

            func removeValue(for key: String) {

                SecItemDelete(makeBaseQuery(for: key) as CFDictionary)
            }

            private func makeBaseQuery(for key: String) -> [String: Any] {

                [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: key,
                ]
            }

            private let serviceName = Bundle.main.bundleIdentifier ?? "SecureTelegram"

        } // Impl

    } // Keychain

} // Storage
