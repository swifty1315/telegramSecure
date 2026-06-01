//
//  Storage+Secure.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import CryptoKit
import Swinject

extension Storage {

    struct Secure {

        enum Error: LocalizedError {

            case missingEncryptedPayload

            var errorDescription: String? {

                switch self {
                case .missingEncryptedPayload:
                    return "Encrypted key payload is invalid."
                }
            }

        } // Error

        struct DialogEncryptionKey: Identifiable, Codable, Equatable {

            let id: UUID
            let dialogID: Int64
            let encryptedKeyData: Data
            let encryptionType: String
            let appliedFrom: Date
            var appliedTo: Date?

        } // DialogEncryptionKey

        struct DecryptedDialogEncryptionKey: Identifiable, Equatable {

            let id: UUID
            let dialogID: Int64
            let key: String
            let encryptionType: String
            let appliedFrom: Date
            let appliedTo: Date?

        } // DecryptedDialogEncryptionKey

        protocol Interface {

            func dialogEncryptionKeys(for dialogID: Int64) throws -> [DecryptedDialogEncryptionKey]

            func addDialogEncryptionKey(
                dialogID: Int64,
                encryptionType: String
            ) throws -> [DecryptedDialogEncryptionKey]

            func terminateActiveDialogEncryptionKey(
                dialogID: Int64
            ) throws -> [DecryptedDialogEncryptionKey]

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                container.register(Interface.self) { _ in
                    UserDefaultsImpl()
                }
                .inObjectScope(.container)
            }

        } // Factory

        final class UserDefaultsImpl: Interface {

            init(userDefaults: UserDefaults = .standard) {

                self.userDefaults = userDefaults
            }

            func dialogEncryptionKeys(for dialogID: Int64) throws -> [DecryptedDialogEncryptionKey] {

                try loadRecords()
                    .filter { $0.dialogID == dialogID }
                    .sorted { $0.appliedFrom < $1.appliedFrom }
                    .map(decrypt)
            }

            func addDialogEncryptionKey(
                dialogID: Int64,
                encryptionType: String
            ) throws -> [DecryptedDialogEncryptionKey] {

                let now = Date()
                let key = Self.makeDialogEncryptionKey()
                var records = try loadRecords()

                if let activeIndex = records.lastIndex(where: { record in
                    record.dialogID == dialogID && record.appliedTo == nil
                }) {
                    records[activeIndex].appliedTo = now
                }

                records.append(
                    .init(
                        id: UUID(),
                        dialogID: dialogID,
                        encryptedKeyData: Data(key.utf8),
                        encryptionType: encryptionType,
                        appliedFrom: now,
                        appliedTo: nil
                    )
                )

                try saveRecords(records)

                return try dialogEncryptionKeys(for: dialogID)
            }

            func terminateActiveDialogEncryptionKey(
                dialogID: Int64
            ) throws -> [DecryptedDialogEncryptionKey] {

                var records = try loadRecords()

                guard let activeIndex = records.lastIndex(where: { record in
                    record.dialogID == dialogID && record.appliedTo == nil
                }) else {
                    return try dialogEncryptionKeys(for: dialogID)
                }

                records[activeIndex].appliedTo = Date()
                try saveRecords(records)

                return try dialogEncryptionKeys(for: dialogID)
            }

            private let userDefaults: UserDefaults
            private let encoder = JSONEncoder()
            private let decoder = JSONDecoder()
            private let storageKey = "storage.secure.mock.dialogEncryptionKeys"

            private func loadRecords() throws -> [DialogEncryptionKey] {

                guard let data = userDefaults.data(forKey: storageKey) else {
                    return []
                }

                return try decoder.decode([DialogEncryptionKey].self, from: data)
            }

            private func saveRecords(_ records: [DialogEncryptionKey]) throws {

                let data = try encoder.encode(records)
                userDefaults.set(data, forKey: storageKey)
            }

            private func decrypt(_ record: DialogEncryptionKey) -> DecryptedDialogEncryptionKey {

                .init(
                    id: record.id,
                    dialogID: record.dialogID,
                    key: String(decoding: record.encryptedKeyData, as: UTF8.self),
                    encryptionType: record.encryptionType,
                    appliedFrom: record.appliedFrom,
                    appliedTo: record.appliedTo
                )
            }

            private static func makeDialogEncryptionKey() -> String {

                Data((0..<32).map { _ in UInt8.random(in: 0...UInt8.max) })
                    .map { String(format: "%02x", $0) }
                    .joined()
            }

        } // UserDefaultsImpl

        final class Impl: Interface {

            init(
                resolver: Resolver,
                fileManager: FileManager = .default
            ) {

                self.keychain = resolver.resolve(Storage.Keychain.Interface.self)!
                self.fileManager = fileManager

                let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                self.rootURL = appSupport.appendingPathComponent("SecureStorage", isDirectory: true)
            }

            func dialogEncryptionKeys(for dialogID: Int64) throws -> [DecryptedDialogEncryptionKey] {

                try loadRecords()
                    .filter { $0.dialogID == dialogID }
                    .sorted { $0.appliedFrom < $1.appliedFrom }
                    .map(decrypt)
            }

            func addDialogEncryptionKey(
                dialogID: Int64,
                encryptionType: String
            ) throws -> [DecryptedDialogEncryptionKey] {

                let now = Date()
                let key = Self.makeDialogEncryptionKey()
                var records = try loadRecords()

                if let activeIndex = records.lastIndex(where: { record in
                    record.dialogID == dialogID && record.appliedTo == nil
                }) {
                    records[activeIndex].appliedTo = now
                }

                records.append(
                    .init(
                        id: UUID(),
                        dialogID: dialogID,
                        encryptedKeyData: try encrypt(key),
                        encryptionType: encryptionType,
                        appliedFrom: now,
                        appliedTo: nil
                    )
                )

                try saveRecords(records)

                do {
                    return try dialogEncryptionKeys(for: dialogID)
                } catch {
                    records.removeAll { $0.dialogID == dialogID }
                    records.append(
                        .init(
                            id: UUID(),
                            dialogID: dialogID,
                            encryptedKeyData: try encrypt(key),
                            encryptionType: encryptionType,
                            appliedFrom: now,
                            appliedTo: nil
                        )
                    )
                    try saveRecords(records)

                    return try dialogEncryptionKeys(for: dialogID)
                }
            }

            func terminateActiveDialogEncryptionKey(
                dialogID: Int64
            ) throws -> [DecryptedDialogEncryptionKey] {

                var records = try loadRecords()

                guard let activeIndex = records.lastIndex(where: { record in
                    record.dialogID == dialogID && record.appliedTo == nil
                }) else {
                    return try dialogEncryptionKeys(for: dialogID)
                }

                records[activeIndex].appliedTo = Date()
                try saveRecords(records)

                return try dialogEncryptionKeys(for: dialogID)
            }

            private let keychain: Storage.Keychain.Interface
            private let fileManager: FileManager
            private let rootURL: URL
            private let encoder = JSONEncoder()
            private let decoder = JSONDecoder()
            private var cachedMasterKeyData: Data?

            private var databaseURL: URL {

                rootURL.appendingPathComponent("dialog-encryption-keys.json", isDirectory: false)
            }

            private func loadRecords() throws -> [DialogEncryptionKey] {

                try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)

                guard fileManager.fileExists(atPath: databaseURL.path(percentEncoded: false)) else {
                    return []
                }

                let data = try Data(contentsOf: databaseURL)
                return try decoder.decode([DialogEncryptionKey].self, from: data)
            }

            private func saveRecords(_ records: [DialogEncryptionKey]) throws {

                try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)

                let data = try encoder.encode(records)
                try data.write(to: databaseURL, options: .atomic)
            }

            private func encrypt(_ key: String) throws -> Data {

                let sealedBox = try AES.GCM.seal(
                    Data(key.utf8),
                    using: masterKey
                )

                guard let combined = sealedBox.combined else {
                    throw Error.missingEncryptedPayload
                }

                return combined
            }

            private func decrypt(_ record: DialogEncryptionKey) throws -> DecryptedDialogEncryptionKey {

                let sealedBox = try AES.GCM.SealedBox(combined: record.encryptedKeyData)
                let data = try AES.GCM.open(sealedBox, using: masterKey)
                let key = String(decoding: data, as: UTF8.self)

                return .init(
                    id: record.id,
                    dialogID: record.dialogID,
                    key: key,
                    encryptionType: record.encryptionType,
                    appliedFrom: record.appliedFrom,
                    appliedTo: record.appliedTo
                )
            }

            private var masterKey: SymmetricKey {

                if let cachedMasterKeyData {
                    return SymmetricKey(data: cachedMasterKeyData)
                }

                if let data = keychain.data(for: Storage.Keychain.Key.secureStorageMasterKey), data.count == 32 {
                    cachedMasterKeyData = data
                    return SymmetricKey(data: data)
                }

                keychain.removeValue(for: Storage.Keychain.Key.secureStorageMasterKey)

                let data = Self.makeRandomKeyData()
                cachedMasterKeyData = data
                keychain.setData(data, for: Storage.Keychain.Key.secureStorageMasterKey)

                return SymmetricKey(data: data)
            }

            private static func makeDialogEncryptionKey() -> String {

                makeRandomKeyData()
                    .map { String(format: "%02x", $0) }
                    .joined()
            }

            private static func makeRandomKeyData() -> Data {

                Data((0..<32).map { _ in UInt8.random(in: 0...UInt8.max) })
            }

        } // Impl

    } // Secure

} // Storage
