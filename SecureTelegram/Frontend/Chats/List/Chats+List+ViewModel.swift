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

        enum Filter: String, CaseIterable, Identifiable, Equatable {

            case all
            case privateDialogs
            case groups

            var id: String {
                rawValue
            }

            var title: String {
                switch self {
                case .all:
                    return "All"
                case .privateDialogs:
                    return "Dialogs"
                case .groups:
                    return "Groups"
                }
            }

        } // Filter

        @MainActor
        protocol Interface: ObservableObject {

            var action: Chats.List.ViewModel.Impl.Action? { get set }
            var navigationTitle: String { get }
            var chipsViewModel: Controls.Chips.ViewModel { get }
            var items: [Chats.List.Item] { get }
            var hasAnyItems: Bool { get }
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
