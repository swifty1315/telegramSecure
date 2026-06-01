//
//  Chats+List+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine
import Swinject
import OSLog

extension Chats.List.ViewModel {

    @MainActor
    final class Impl: Interface {

        enum Action: Equatable {

            case openDialog

        } // Action

        init(resolver: Resolver) {

            self.controller = resolver.resolve(Chats.List.Controller.Interface.self)!
            self.dialogViewModel = resolver.resolve(Chats.Dialog.ViewModel.Impl.self)!
            self.chipsViewModel = .init(
                items: Self.makeChipItems(),
                selectedItemID: Chats.List.ViewModel.Filter.all.id
            )

            bindChips()
        }

        @Published var action: Action?
        @Published private(set) var items: [Chats.List.Item] = []
        @Published private var selectedFilter: Chats.List.ViewModel.Filter = .all
        @Published private(set) var isLoading = false
        @Published private(set) var errorMessage: String?
        @Published private(set) var hasAuthorizationExpired = false

        let dialogViewModel: Chats.Dialog.ViewModel.Impl
        let chipsViewModel: Controls.Chips.ViewModel

        var hasAnyItems: Bool {

            allItems.isEmpty == false
        }

        var navigationTitle: String {

            "Dialogs"
        }

        var emptyTitle: String {

            "No dialogs yet"
        }

        var emptyMessage: String {

            "When TDLib loads your chats, they will appear here."
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

            dialogViewModel.configure(
                chatID: item.id,
                title: item.title,
                avatarLocalPath: item.avatarLocalPath
            )
            action = .openDialog
        }

        func consumeAction() {

            action = nil
        }

        private let controller: any Chats.List.Controller.Interface
        private let logger = Logger.chats
        private var allItems: [Chats.List.Item] = []
        private var cancellables: Set<AnyCancellable> = []
        private var didLoad = false

        private static func makeChipItems() -> [Controls.Chips.ViewModel.Item] {

            Chats.List.ViewModel.Filter.allCases.map { filter in
                .init(id: filter.id, title: filter.title)
            }
        }

        private func bindChips() {

            chipsViewModel.$action
                .compactMap { $0 }
                .sink { [weak self] action in
                    self?.handleChipsAction(action)
                }
                .store(in: &cancellables)
        }

        private func handleChipsAction(_ action: Controls.Chips.ViewModel.Action) {

            switch action {
            case .didSelectItem(let id):
                guard let filter = Chats.List.ViewModel.Filter(rawValue: id) else {
                    return
                }

                selectedFilter = filter
                applySelectedFilter()
                chipsViewModel.consumeAction()
            }
        }

        private func applySelectedFilter() {

            switch selectedFilter {
            case .all:
                items = allItems
            case .privateDialogs:
                items = allItems.filter { $0.kind == .privateDialog }
            case .groups:
                items = allItems.filter { $0.kind == .group }
            }
        }

        private func fetchDialogs() async {

            isLoading = true
            errorMessage = nil
            hasAuthorizationExpired = false
            defer { isLoading = false }

            do {
                logger.info("*** CHATS list fetch started.")
                allItems = try await controller.fetchDialogs(limit: 50)
                applySelectedFilter()
                logger.info("*** CHATS list fetch finished. count=\(self.allItems.count, privacy: .public).")
            } catch {
                logger.error("*** CHATS list fetch failed: \(self.makeErrorMessage(from: error), privacy: .public).")
                if let error = error as? TelegramClient.Error,
                   error == .unauthorized {
                    logger.warning("*** CHATS list session expired. Returning to authorization flow.")
                    allItems = []
                    items = []
                    errorMessage = nil
                    hasAuthorizationExpired = true
                    return
                }

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

} // Chats.List.ViewModel
