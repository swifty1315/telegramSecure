//
//  Networking+Endpoint.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation

extension Networking {

    struct Endpoint: Equatable {

        let scheme: String
        let host: String
        let path: String
        let queryItems: [URLQueryItem]?

        init(
            scheme: String = Networking.Scheme.https,
            host: String = Networking.Host.base,
            path: String,
            queryItems: [URLQueryItem]? = nil
        ) {

            self.scheme = scheme
            self.host = host
            self.path = path
            self.queryItems = queryItems
        }

    } // Endpoint

} // Networking
