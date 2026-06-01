//
//  Settings+DialogsEncryption+Setup+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import Foundation
import Combine
import Swinject

extension Settings.DialogsEncryption.Setup.ViewModel {

    @MainActor
    final class Impl: Interface {

        init(resolver: Resolver) {

            self.storage = resolver.resolve(Storage.Secure.Interface.self)!
            self.addKeyButtonViewModel = .init(
                title: "Add key",
                style: .primary
            )
            self.terminateEncryptionButtonViewModel = .init(
                title: "Terminate Encryption",
                style: .plainWarning
            )
            self.addKeyButtonViewModel.action = { [weak self] in
                self?.addKey()
            }
            self.terminateEncryptionButtonViewModel.action = { [weak self] in
                self?.terminateEncryption()
            }
        }

        @Published private(set) var records: [KeyRecord] = []
        @Published private(set) var errorMessage: String?

        let addKeyButtonViewModel: Controls.Button.ViewModel
        let terminateEncryptionButtonViewModel: Controls.Button.ViewModel

        var navigationTitle: String {

            dialogTitle.isEmpty ? "Encryption" : dialogTitle
        }

        var dialogTitle: String {

            dialog?.title ?? ""
        }

        var emptyTitle: String {

            "You do not use any keys for the dialog"
        }

        func configure(dialog: Chats.List.Item) {

            self.dialog = dialog
            loadRecords(for: dialog.id)
        }

        func addKey() {

            guard let dialog else {
                return
            }

            do {
                errorMessage = nil
                records = try storage.addDialogEncryptionKey(
                    dialogID: dialog.id,
                    encryptionType: "AES-256-GCM"
                )
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
        }

        func terminateEncryption() {

            guard let dialog else {
                return
            }

            do {
                errorMessage = nil
                records = try storage.terminateActiveDialogEncryptionKey(dialogID: dialog.id)
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
        }

        func isActiveRecord(_ record: KeyRecord) -> Bool {

            record.appliedTo == nil && records.last?.id == record.id
        }

        private let storage: Storage.Secure.Interface
        private var dialog: Chats.List.Item?

        private func loadRecords(for dialogID: Int64) {

            do {
                errorMessage = nil
                records = try storage.dialogEncryptionKeys(for: dialogID)
            } catch {
                records = []
                errorMessage = makeErrorMessage(from: error)
            }
        }

        private func makeErrorMessage(from error: Error) -> String {

            (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

    } // Impl

} // Settings.DialogsEncryption.Setup.ViewModel
