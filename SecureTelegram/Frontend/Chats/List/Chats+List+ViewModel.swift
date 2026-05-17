//
//  Chats+List+ViewModel.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine

extension Chats.List {

    struct ViewModel {

        @MainActor
        protocol Interface: ObservableObject {

            var action: Chats.List.ViewModel.Impl.Action? { get set }
            var navigationTitle: String { get }
            var title: String { get }
            var subtitle: String { get }
            var items: [Chats.List.Item] { get }
            var isLoading: Bool { get }
            var emptyTitle: String { get }
            var emptyMessage: String { get }
            var errorMessage: String? { get }
            var hasAuthorizationExpired: Bool { get }
            var dialogViewModel: Chats.Dialog.ViewModel.Impl { get }

            func onAppear()
            func refresh()
            func didTapDialog(_ item: Chats.List.Item)
            func consumeAction()

        } // Interface

    } // ViewModel

} // Chats.List
