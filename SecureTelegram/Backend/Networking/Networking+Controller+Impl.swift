//
//  Networking+Controller+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Network
import Swinject

extension Networking.Controller {

    final class Impl: Interface {

        init(resolver: Resolver) {

            self.requestComposer = resolver.resolve(Networking.RequestComposer.Interface.self)!
            self.session = Self.makeSession()

            monitor.pathUpdateHandler = { [weak self] path in
                self?.isConnected = path.status == .satisfied
            }

            monitor.start(queue: DispatchQueue(label: "SecureTelegram.Networking.Monitor"))
        }

        deinit {

            monitor.cancel()
        }

        var isNetworkConnectionPresent: Bool {

            isConnected
        }

        func clearCache() {

            session.configuration.urlCache?.removeAllCachedResponses()
        }

        func clearCache(for request: Networking.Request) {

            do {
                let httpRequest = try requestComposer.httpRequest(
                    with: request,
                    basicHeaders: Self.basicHeaders
                )

                session.configuration.urlCache?.removeCachedResponse(for: httpRequest)

            } catch {
                return
            }
        }

        func data(for url: URL) async throws -> Networking.Response {

            guard isConnected else {
                throw Networking.Error.noInternetConnection
            }

            let (data, response) = try await session.data(from: url)
            let networkingResponse = try mapResponse(response: response, data: data)

            try validate(response: networkingResponse, acceptableCodes: defaultSuccessStatusCodes)

            return networkingResponse
        }

        func perform(_ request: Networking.Request) async throws -> Networking.Response {

            guard isConnected else {
                throw Networking.Error.noInternetConnection
            }

            let httpRequest = try requestComposer.httpRequest(
                with: request,
                basicHeaders: Self.basicHeaders
            )

            if request.cacheable,
               let cachedResponse = session.configuration.urlCache?.cachedResponse(for: httpRequest) {

                let response = try mapResponse(
                    response: cachedResponse.response,
                    data: cachedResponse.data
                )

                try validate(
                    response: response,
                    acceptableCodes: request.acceptableStatusCodes ?? defaultSuccessStatusCodes
                )

                return response
            }

            let (data, urlResponse) = try await session.data(for: httpRequest)
            let response = try mapResponse(response: urlResponse, data: data)

            try validate(
                response: response,
                acceptableCodes: request.acceptableStatusCodes ?? defaultSuccessStatusCodes
            )

            if request.cacheable {
                session.configuration.urlCache?.storeCachedResponse(
                    CachedURLResponse(response: urlResponse, data: data),
                    for: httpRequest
                )
            }

            return response
        }

        private static let basicLanguage = Locale.preferredLanguages.first ?? "en"

        private static let basicHeaders: Networking.Headers = [
            Networking.Keys.contentType: Networking.Header.Value.applicationJson,
            Networking.Keys.accept: Networking.Header.Value.applicationJson,
            Networking.Keys.acceptLanguage: basicLanguage,
            Networking.Keys.xClientType: Networking.Header.Value.ios,
        ]

        private let requestComposer: Networking.RequestComposer.Interface
        private let session: URLSession
        private let monitor = NWPathMonitor()
        private let defaultSuccessStatusCodes = IndexSet(200..<300)

        private var isConnected = true

        private static func makeSession(delegate: URLSessionDelegate? = nil) -> URLSession {

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 60
            configuration.requestCachePolicy = .useProtocolCachePolicy
            configuration.urlCache = URLCache.shared

            return URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
        }

        private func mapResponse(
            response: URLResponse,
            data: Data
        ) throws -> Networking.Response {

            guard let httpResponse = response as? HTTPURLResponse else {
                throw Networking.Error.invalidResponse
            }

            return Networking.Response(
                statusCode: httpResponse.statusCode,
                payload: data
            )
        }

        private func validate(
            response: Networking.Response,
            acceptableCodes: IndexSet
        ) throws {

            guard acceptableCodes.contains(response.statusCode) else {
                if response.statusCode == 401 || response.statusCode == 403 {
                    throw Networking.Error.unauthorized
                }

                throw Networking.Error.unacceptableStatusCode(
                    response.statusCode,
                    payload: response.payload
                )
            }
        }

    } // Impl

} // Networking.Controller
