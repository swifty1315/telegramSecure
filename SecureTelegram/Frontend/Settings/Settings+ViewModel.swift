//
//  Settings+ViewModel.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine

extension Settings {

    struct ViewModel {

        @MainActor
        protocol Interface: ObservableObject {

            var action: Settings.ViewModel.Impl.Action? { get set }
            var navigationTitle: String { get }
            var sections: [Settings.ViewModel.Impl.Section] { get }
            var dialogsEncryptionViewModel: Settings.DialogsEncryption.ViewModel.Impl { get }

            func didTapRow(_ row: Settings.ViewModel.Impl.Row)
            func consumeAction()

        } // Interface

    } // ViewModel

} // Settings
