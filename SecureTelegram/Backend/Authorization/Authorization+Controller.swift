//
//  Authorization+Controller.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Authorization {

    struct Controller {

        protocol Interface {

            var state: Authorization.State { get }

            func initialize() async throws -> Authorization.State

            func sendCode(to phoneNumber: String) async throws -> Authorization.State

            func confirmCode(_ code: String) async throws -> Authorization.State

            func confirmPassword(_ password: String) async throws -> Authorization.State

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

    } // Controller

} // Authorization
