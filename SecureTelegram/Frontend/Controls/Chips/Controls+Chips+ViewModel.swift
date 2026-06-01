//
//  Controls+Chips+ViewModel.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import Combine

extension Controls.Chips {

    @MainActor
    final class ViewModel: ObservableObject {

        struct Item: Identifiable, Equatable {

            let id: String
            let title: String

        } // Item

        enum Action: Equatable {

            case didSelectItem(id: String)

        } // Action

        init(
            items: [Item],
            selectedItemID: String
        ) {

            self.items = items
            self.selectedItemID = selectedItemID
        }

        @Published private(set) var items: [Item]
        @Published private(set) var selectedItemID: String
        @Published var action: Action?

        func didTapItem(_ item: Item) {

            guard selectedItemID != item.id else {
                return
            }

            selectedItemID = item.id
            action = .didSelectItem(id: item.id)
        }

        func consumeAction() {

            action = nil
        }

    } // ViewModel

} // Controls.Chips
