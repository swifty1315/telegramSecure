//
//  Authorization+Router.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine
import SwiftUI

extension Authorization {

    @MainActor
    final class Router: ObservableObject {

        enum Node: Hashable {

            case alert

        } // Node

        enum Route: Hashable, Identifiable {

            case code
            case chatsList

            var id: String {

                switch self {
                case .code:
                    return "code"
                case .chatsList:
                    return "chatsList"
                }
            }

        } // Route

        @Published var route: Route?
        @Published var node: Node?

        func bindNode(_ node: Node) -> Binding<Bool> {

            Binding(
                get: { self.node == node },
                set: { isPresented in
                    if isPresented == false, self.node == node {
                        self.node = nil
                    }
                }
            )
        }

    } // Router

} // Authorization
