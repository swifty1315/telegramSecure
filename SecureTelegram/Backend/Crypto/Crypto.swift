//
//  Crypto.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import Swinject

struct Crypto {

    struct Factory {

        static func register(with container: Container) {

            Crypto.Controller.Factory.register(with: container)
        }

    } // Factory

} // Crypto
