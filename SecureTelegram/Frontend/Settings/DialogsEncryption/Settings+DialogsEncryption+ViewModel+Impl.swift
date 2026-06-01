//
//  Settings+DialogsEncryption+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine
import Swinject

extension Settings.DialogsEncryption.ViewModel {

    @MainActor
    final class Impl: Interface {

        enum Action: Equatable {

            case openSetup

        } // Action

        init(resolver: Resolver) {

            self.controller = resolver.resolve(Chats.List.Controller.Interface.self)!
            self.setupViewModel = resolver.resolve(Settings.DialogsEncryption.Setup.ViewModel.Impl.self)!
        }

        @Published var action: Action?
        @Published private(set) var items: [Chats.List.Item] = []
        @Published private(set) var isLoading = false
        @Published private(set) var errorMessage: String?

        let setupViewModel: Settings.DialogsEncryption.Setup.ViewModel.Impl

        var navigationTitle: String {

            "Dialogs Encryption"
        }

        var subtitle: String {

            "Customize encryption for private dialogs."
        }

        var emptyTitle: String {

            "No private dialogs"
        }

        var emptyMessage: String {

            "Private Telegram conversations will appear here when TDLib loads them."
        }

        func onAppear() {

            guard didLoad == false else {
                return
            }

            didLoad = true
            refresh()
        }

        func refresh() {

            guard isLoading == false else {
                return
            }

            Task {
                await fetchDialogs()
            }
        }

        func didTapDialog(_ item: Chats.List.Item) {

            setupViewModel.configure(dialog: item)
            action = .openSetup
        }

        func consumeAction() {

            action = nil
        }

        private let controller: any Chats.List.Controller.Interface
        private var didLoad = false

        private func fetchDialogs() async {

            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                items = try await controller.fetchDialogs(limit: 100)
                    .filter { $0.kind == .privateDialog }
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
        }

        private func makeErrorMessage(from error: Swift.Error) -> String {

            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               description.isEmpty == false {
                return description
            }

            return error.localizedDescription
        }

    } // Impl

} // Settings.DialogsEncryption.ViewModel
