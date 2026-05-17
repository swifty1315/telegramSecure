//
//  Chats+List+Router.swift
//  SecureTelegram
//
//  Created by Codex on 12.05.2026.
//

import SwiftUI
import Combine

extension Chats.List {

    @MainActor
    final class Router: ObservableObject {

        enum Route: Hashable, Identifiable {

            case dialog

            var id: String {

                switch self {
                case .dialog:
                    return "dialog"
                }
            }

        } // Route

        @Published var route: Route?

    } // Router

} // Chats.List
