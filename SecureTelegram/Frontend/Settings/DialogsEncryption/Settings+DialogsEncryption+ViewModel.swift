//
//  Settings+DialogsEncryption+ViewModel.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine

extension Settings.DialogsEncryption {

    struct ViewModel {

        @MainActor
        protocol Interface: ObservableObject {

            var action: Settings.DialogsEncryption.ViewModel.Impl.Action? { get set }
            var navigationTitle: String { get }
            var subtitle: String { get }
            var items: [Chats.List.Item] { get }
            var emptyTitle: String { get }
            var emptyMessage: String { get }
            var isLoading: Bool { get }
            var errorMessage: String? { get }
            var setupViewModel: Settings.DialogsEncryption.Setup.ViewModel.Impl { get }

            func onAppear()
            func refresh()
            func didTapDialog(_ item: Chats.List.Item)
            func consumeAction()

        } // Interface

    } // ViewModel

} // Settings.DialogsEncryption
