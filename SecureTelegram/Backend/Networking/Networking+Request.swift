//
//  Networking+Request.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation

extension Networking {

    struct Request: Equatable {

        enum Method: String {

            case get = "GET"
            case post = "POST"
            case patch = "PATCH"
            case put = "PUT"
            case delete = "DELETE"

        } // Method

        enum Authorization: Equatable {

            case none
            case bearer(String)

        } // Authorization

        let body: Data?
        let headers: Networking.Headers
        let method: Method
        let endpoint: Networking.Endpoint
        let acceptableStatusCodes: IndexSet?
        let cacheable: Bool
        let authorization: Authorization

        init(
            body: Data? = nil,
            headers: Networking.Headers = [:],
            method: Method,
            endpoint: Networking.Endpoint,
            acceptableStatusCodes: IndexSet? = nil,
            cacheable: Bool = false,
            authorization: Authorization = .none
        ) {

            self.body = body
            self.headers = headers
            self.method = method
            self.endpoint = endpoint
            self.acceptableStatusCodes = acceptableStatusCodes
            self.cacheable = cacheable
            self.authorization = authorization
        }

    } // Request

} // Networking
