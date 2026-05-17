//
//  Networking+RequestComposer.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Networking {

    struct RequestComposer {

        protocol Interface {

            func httpRequest(
                with request: Networking.Request,
                basicHeaders: Networking.Headers
            ) throws -> URLRequest

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                container.register(Interface.self) { _ in
                    Impl()
                }
                .inObjectScope(.container)
            }

        } // Factory

        final class Impl: Interface {

            func httpRequest(
                with request: Networking.Request,
                basicHeaders: Networking.Headers
            ) throws -> URLRequest {

                var components = URLComponents()
                components.scheme = request.endpoint.scheme
                components.host = request.endpoint.host
                components.path = request.endpoint.path
                components.queryItems = request.endpoint.queryItems

                guard let url = components.url else {
                    throw Networking.Error.invalidRequest
                }

                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = request.method.rawValue
                urlRequest.httpBody = request.body

                basicHeaders.forEach { key, value in
                    urlRequest.setValue(value, forHTTPHeaderField: key)
                }

                request.headers.forEach { key, value in
                    urlRequest.setValue(value, forHTTPHeaderField: key)
                }

                switch request.authorization {
                case .none:
                    break
                case .bearer(let token):
                    urlRequest.setValue(
                        "\(Networking.Keys.bearer) \(token)",
                        forHTTPHeaderField: Networking.Keys.authorization
                    )
                }

                return urlRequest
            }

        } // Impl

    } // RequestComposer

} // Networking
