//
//  Networking.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

struct Networking {

    typealias Headers = [String: String]

    struct Factory {

        static func register(with container: Container) {

            Networking.RequestComposer.Factory.register(with: container)
            Networking.Controller.Factory.register(with: container)
        }

    } // Factory

    enum Error: LocalizedError, Equatable {

        case generic
        case invalidRequest
        case invalidResponse
        case unauthorized
        case noInternetConnection
        case unacceptableStatusCode(Int, payload: Data?)

        var errorDescription: String? {

            switch self {
            case .generic:
                return "Something went wrong."
            case .invalidRequest:
                return "Failed to build request."
            case .invalidResponse:
                return "Received invalid response."
            case .unauthorized:
                return "Authorization is required."
            case .noInternetConnection:
                return "No internet connection."
            case .unacceptableStatusCode(let statusCode, _):
                return "Unexpected status code: \(statusCode)."
            }
        }

    } // Error

    struct Response: Equatable {

        let statusCode: Int
        let payload: Data?

    } // Response

    struct Header {

        struct Value {

            static let applicationJson = "application/json"
            static let formUrlEncoded = "application/x-www-form-urlencoded"
            static let ios = "ios"
        }

    } // Header

    struct Host {

        static let base = AppConfiguration.Networking.baseHost

    } // Host

    struct Scheme {

        static let https = AppConfiguration.Networking.scheme

    } // Scheme

    struct Paths {

        struct Auth {

            static let sendCode = "/auth/send-code"
            static let confirmCode = "/auth/confirm-code"
            static let password = "/auth/password"
        }

        struct User {

            static let profile = "/user/profile"
        }

    } // Paths

    struct Keys {

        static let authorization = "Authorization"
        static let bearer = "Bearer"
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let acceptLanguage = "Accept-Language"
        static let xClientType = "X-Client-Type"

    } // Keys

} // Networking

extension Networking {

    private struct ResponseData<T: Decodable>: Decodable {

        let data: T

    } // ResponseData

    static func decodeResponse<T: Decodable>(
        data: Data?,
        type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {

        guard let data else {
            throw Networking.Error.invalidResponse
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw Networking.Error.invalidResponse
        }
    }

    static func decodeResponseData<T: Decodable>(
        data: Data?,
        type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {

        guard let data else {
            throw Networking.Error.invalidResponse
        }

        do {
            return try decoder.decode(ResponseData<T>.self, from: data).data
        } catch {
            throw Networking.Error.invalidResponse
        }
    }

} // Networking
