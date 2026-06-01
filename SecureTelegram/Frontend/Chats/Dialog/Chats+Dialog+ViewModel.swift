//
//  Chats+Dialog+ViewModel.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine

extension Chats.Dialog {

    struct ViewModel {

        struct MessageSection: Identifiable, Equatable {

            let id: Date
            let day: Date
            let messages: [Chats.Dialog.Message]

        } // MessageSection

        @MainActor
        protocol Interface: ObservableObject {

            var navigationTitle: String { get }
            var title: String { get }
            var subtitle: String { get }
            var avatarLocalPath: String? { get }
            var messages: [Chats.Dialog.Message] { get }
            var messageSections: [MessageSection] { get }
            var composerViewModel: Chats.Dialog.Composer.ViewModel.Impl { get }
            var isLoading: Bool { get }
            var emptyTitle: String { get }
            var emptyMessage: String { get }
            var errorMessage: String? { get }

            func configure(
                chatID: Int64,
                title: String,
                avatarLocalPath: String?
            )
            func onAppear()
            func onDisappear()
            func refresh()

        } // Interface

    } // ViewModel

} // Chats.Dialog
