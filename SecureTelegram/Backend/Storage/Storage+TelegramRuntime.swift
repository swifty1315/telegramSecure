//
//  Storage+TelegramRuntime.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import OSLog
import Swinject

extension Storage {

    struct TelegramRuntime {

        enum Error: LocalizedError {

            case missingDatabaseEncryptionKey

            var errorDescription: String? {

                switch self {
                case .missingDatabaseEncryptionKey:
                    return "TDLib database exists, but its encryption key is missing."
                }
            }

        } // Error

        protocol Interface {

            var databaseURL: URL { get }

            var filesURL: URL { get }

            var databaseEncryptionKey: Data { get }

            func prepare() throws

            func reset() throws

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

            init(
                resolver: Resolver,
                fileManager: FileManager = .default
            ) {

                self.fileManager = fileManager
                self.keychain = resolver.resolve(Storage.Keychain.Interface.self)!

                let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                self.rootURL = appSupport.appendingPathComponent("TelegramRuntime", isDirectory: true)
            }

            var databaseURL: URL {

                rootURL.appendingPathComponent("Database", isDirectory: true)
            }

            var filesURL: URL {

                rootURL.appendingPathComponent("Files", isDirectory: true)
            }

            var databaseEncryptionKey: Data {

                if let cachedDatabaseEncryptionKey {
                    return cachedDatabaseEncryptionKey
                }

                logger.error("Telegram runtime encryption key requested before prepare resolved it.")
                return Data()
            }

            func prepare() throws {

                logger.debug("*** STORAGE preparing Telegram runtime storage at: \(self.path(for: self.rootURL), privacy: .public).")
                try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: databaseURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: filesURL, withIntermediateDirectories: true)
                cachedDatabaseEncryptionKey = try resolveDatabaseEncryptionKey()
            }

            func reset() throws {

                logger.warning("*** STORAGE resetting Telegram runtime storage.")
                try purgeRuntimeArtifacts()

                cachedDatabaseEncryptionKey = nil
                keychain.removeValue(for: Storage.Keychain.Key.tdlibDatabaseEncryptionKey)

                try prepare()
            }

            private let fileManager: FileManager
            private let keychain: Storage.Keychain.Interface
            private let rootURL: URL
            private let logger = Logger.storage
            private var cachedDatabaseEncryptionKey: Data?

            private var databaseEncryptionKeyURL: URL {

                rootURL.appendingPathComponent("database-encryption-key.bin", isDirectory: false)
            }

            private func purgeRuntimeArtifacts() throws {

                let candidateURLs = makePurgeCandidateURLs()

                for candidateURL in candidateURLs where fileManager.fileExists(atPath: path(for: candidateURL)) {
                    logger.warning("*** STORAGE removing Telegram runtime artifact at: \(self.path(for: candidateURL), privacy: .public).")
                    try fileManager.removeItem(at: candidateURL)
                }
            }

            private func makePurgeCandidateURLs() -> [URL] {

                var candidates: [URL] = [
                    rootURL,
                    databaseURL,
                    filesURL,
                ]

                let searchRoots = [
                    fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
                    fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
                    fileManager.temporaryDirectory,
                ]
                .compactMap { $0 }

                for searchRoot in searchRoots {
                    guard let childURLs = try? fileManager.contentsOfDirectory(
                        at: searchRoot,
                        includingPropertiesForKeys: nil
                    ) else {
                        continue
                    }

                    for childURL in childURLs {
                        let normalizedName = childURL.lastPathComponent.lowercased()

                        if normalizedName.contains("telegramruntime")
                            || normalizedName.contains("tdlib")
                            || normalizedName.contains("telegram") {
                            candidates.append(childURL)
                        }
                    }
                }

                return Array(Set(candidates))
            }

            private func resolveDatabaseEncryptionKey() throws -> Data {

                if let storedKey = keychain.data(for: Storage.Keychain.Key.tdlibDatabaseEncryptionKey) {
                    try persistDatabaseEncryptionKeyToFileIfNeeded(storedKey)
                    return storedKey
                }

                if let storedKey = try loadDatabaseEncryptionKeyFromFile() {
                    keychain.setData(storedKey, for: Storage.Keychain.Key.tdlibDatabaseEncryptionKey)
                    return storedKey
                }

                if databaseArtifactsExist {
                    logger.error("*** STORAGE TDLib database exists, but encryption key is missing in both keychain and runtime file.")
                    throw TelegramRuntime.Error.missingDatabaseEncryptionKey
                }

                let generatedKey = Data((0..<64).map { _ in UInt8.random(in: 0...UInt8.max) })
                keychain.setData(generatedKey, for: Storage.Keychain.Key.tdlibDatabaseEncryptionKey)
                try persistDatabaseEncryptionKeyToFileIfNeeded(generatedKey)

                return generatedKey
            }

            private var databaseArtifactsExist: Bool {

                if fileManager.fileExists(atPath: path(for: rootURL)) == false {
                    return false
                }

                let artifactPaths = [
                    path(for: databaseURL.appendingPathComponent("td.binlog", isDirectory: false)),
                    path(for: databaseURL.appendingPathComponent("db.sqlite", isDirectory: false)),
                    path(for: databaseURL.appendingPathComponent("db.sqlite-shm", isDirectory: false)),
                    path(for: databaseURL.appendingPathComponent("db.sqlite-wal", isDirectory: false)),
                ]

                return artifactPaths.contains { fileManager.fileExists(atPath: $0) }
            }

            private func persistDatabaseEncryptionKeyToFileIfNeeded(_ key: Data) throws {

                if fileManager.fileExists(atPath: path(for: databaseEncryptionKeyURL)) {
                    return
                }

                try key.write(to: databaseEncryptionKeyURL, options: .atomic)
            }

            private func loadDatabaseEncryptionKeyFromFile() throws -> Data? {

                guard fileManager.fileExists(atPath: path(for: databaseEncryptionKeyURL)) else {
                    return nil
                }

                return try Data(contentsOf: databaseEncryptionKeyURL)
            }

            private func path(for url: URL) -> String {

                url.path(percentEncoded: false)
            }

        } // Impl

    } // TelegramRuntime

} // Storage
