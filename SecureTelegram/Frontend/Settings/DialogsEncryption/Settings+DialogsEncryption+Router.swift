//
//  Settings+DialogsEncryption+Router.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import Combine

extension Settings.DialogsEncryption {

    final class Router: ObservableObject {

        enum Route: String, Identifiable {

            case setup

            var id: String { rawValue }

        } // Route

        @Published var route: Route?

    } // Router

} // Settings.DialogsEncryption
