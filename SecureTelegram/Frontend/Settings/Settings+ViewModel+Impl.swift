//
//  Settings+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine
import Swinject

extension Settings.ViewModel {

    @MainActor
    final class Impl: Interface {

        enum Action: Equatable {

            case openDialogsEncryption

        } // Action

        struct Row: Identifiable, Hashable {

            let id: String
            let title: String
            let subtitle: String

        } // Row

        struct Section: Identifiable, Hashable {

            let id: String
            let rows: [Row]

        } // Section

        init(resolver: Resolver) {

            self.dialogsEncryptionViewModel = resolver.resolve(Settings.DialogsEncryption.ViewModel.Impl.self)!
        }

        @Published var action: Action?

        let dialogsEncryptionViewModel: Settings.DialogsEncryption.ViewModel.Impl

        var navigationTitle: String {

            "Settings"
        }

        var sections: [Section] {

            [
                .init(
                    id: "dialogs-encryption",
                    rows: [
                        .init(
                            id: "dialogs-encryption",
                            title: "Dialogs Encryption",
                            subtitle: "Customize your dialog encryption"
                        )
                    ]
                ),
                .init(
                    id: "general",
                    rows: [
                        .init(
                            id: "session",
                            title: "Session",
                            subtitle: "Current Telegram session and device state."
                        ),
                        .init(
                            id: "profile",
                            title: "My Profile",
                            subtitle: "Account identity, username and contact info."
                        ),
                        .init(
                            id: "security",
                            title: "Security",
                            subtitle: "Two-step verification and protected access options."
                        )
                    ]
                )
            ]
        }

        func didTapRow(_ row: Row) {

            switch row.id {
            case "dialogs-encryption":
                action = .openDialogsEncryption
            default:
                break
            }
        }

        func consumeAction() {

            action = nil
        }

    } // Impl

} // Settings.ViewModel
