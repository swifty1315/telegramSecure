//
//  SecureTelegramTests.swift
//  SecureTelegramTests
//
//  Created by Ilya on 21.04.2026.
//

import Testing
import Foundation
@testable import SecureTelegram
import Swinject

@MainActor
struct SecureTelegramTests {

    @Test func networkingContainerResolvesController() async throws {

        let container = AppDependency.makeContainer()
        let controller = container.resolve(Networking.Controller.Interface.self)

        #expect(controller != nil)
    }

    @Test func networkingContainerResolvesAuthorizationController() async throws {

        let container = AppDependency.makeContainer()
        let controller = container.resolve(Authorization.Controller.Interface.self)

        #expect(controller != nil)
    }

    @Test func requestComposerBuildsBearerRequest() async throws {

        let composer = Networking.RequestComposer.Impl()
        let request = Networking.Request(

            method: .post,
            endpoint: .init(path: Networking.Paths.Auth.sendCode),
            authorization: .bearer("token-123")
        )

        let urlRequest = try composer.httpRequest(
            with: request,
            basicHeaders: [Networking.Keys.accept: Networking.Header.Value.applicationJson]
        )

        #expect(urlRequest.url?.absoluteString == "https://api.telegram.org/auth/send-code")
        #expect(urlRequest.value(forHTTPHeaderField: Networking.Keys.accept) == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: Networking.Keys.authorization) == "Bearer token-123")
    }

}
