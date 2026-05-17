//
//  AppTabs+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine
import Swinject

extension AppTabs.ViewModel {

    @MainActor
    final class Impl: Interface {

        enum Tab: Hashable {

            case chats
            case settings

        } // Tab

        init(resolver: Resolver) {

            self.chatsListViewModel = resolver.resolve(Chats.List.ViewModel.Impl.self)!
            self.settingsViewModel = resolver.resolve(Settings.ViewModel.Impl.self)!
        }

        @Published var selectedTab: Tab = .chats

        let chatsListViewModel: Chats.List.ViewModel.Impl
        let settingsViewModel: Settings.ViewModel.Impl

        func selectTab(_ tab: Tab) {

            selectedTab = tab
        }

        func reset() {

            selectedTab = .chats
        }

    } // Impl

} // AppTabs.ViewModel
