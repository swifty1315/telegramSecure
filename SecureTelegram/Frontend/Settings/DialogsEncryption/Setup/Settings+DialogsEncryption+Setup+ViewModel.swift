//
//  Settings+DialogsEncryption+Setup+ViewModel.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import Combine

extension Settings.DialogsEncryption.Setup {

    struct ViewModel {

        typealias KeyRecord = Storage.Secure.DecryptedDialogEncryptionKey

        @MainActor
        protocol Interface: ObservableObject {

            var navigationTitle: String { get }
            var dialogTitle: String { get }
            var emptyTitle: String { get }
            var records: [KeyRecord] { get }
            var errorMessage: String? { get }
            var addKeyButtonViewModel: Controls.Button.ViewModel { get }
            var terminateEncryptionButtonViewModel: Controls.Button.ViewModel { get }

            func configure(dialog: Chats.List.Item)
            func addKey()
            func terminateEncryption()
            func isActiveRecord(_ record: KeyRecord) -> Bool

        } // Interface

    } // ViewModel

} // Settings.DialogsEncryption.Setup
