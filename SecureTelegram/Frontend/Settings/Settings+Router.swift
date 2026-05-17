//
//  Settings+Router.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine

extension Settings {

    final class Router: ObservableObject {

        enum Route: String, Identifiable {

            case dialogsEncryption

            var id: String { rawValue }

        } // Route

        @Published var route: Route?

    } // Router

} // Settings
