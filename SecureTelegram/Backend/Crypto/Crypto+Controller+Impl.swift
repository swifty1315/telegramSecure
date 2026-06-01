//
//  Crypto+Controller+Impl.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation

extension Crypto.Controller {

    final class Impl: Interface {

        func perform(
            algorithm: String,
            key: String,
            message: String,
            action: Action
        ) throws -> String {

            switch action {
            case .encrypt:
                return encrypt(
                    algorithm: algorithm,
                    key: key,
                    message: message
                )

            case .decrypt:
                return decrypt(
                    key: key,
                    message: message
                )
            }
        }

        private func encrypt(
            algorithm: String,
            key: String,
            message: String
        ) -> String {

            guard message.isEmpty == false else {
                return message
            }

            let payload = MockPayload(
                algorithm: algorithm,
                key: key,
                message: message
            )
            let data = (try? encoder.encode(payload)) ?? Data()

            return Self.prefix + data.base64EncodedString()
        }

        private func decrypt(
            key: String,
            message: String
        ) -> String {

            guard message.hasPrefix(Self.prefix) else {
                return message
            }

            let encodedPayload = String(message.dropFirst(Self.prefix.count))

            guard let data = Data(base64Encoded: encodedPayload),
                  let payload = try? decoder.decode(MockPayload.self, from: data),
                  payload.key == key else {
                return message
            }

            return payload.message
        }

        private struct MockPayload: Codable {

            let algorithm: String
            let key: String
            let message: String

        } // MockPayload

        private let encoder = JSONEncoder()
        private let decoder = JSONDecoder()
        private static let prefix = "securetelegram-mock://"

    } // Impl

} // Crypto.Controller
