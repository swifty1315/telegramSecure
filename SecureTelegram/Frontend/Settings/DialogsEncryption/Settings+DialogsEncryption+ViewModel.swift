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

            var navigationTitle: String { get }
            var subtitle: String { get }
            var items: [Chats.List.Item] { get }
            var isLoading: Bool { get }
            var errorMessage: String? { get }

            func onAppear()
            func refresh()

        } // Interface

    } // ViewModel

} // Settings.DialogsEncryption
