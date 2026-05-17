//
//  AppTabs+ViewModel.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine

extension AppTabs {

    struct ViewModel {

        @MainActor
        protocol Interface: ObservableObject {

            var selectedTab: AppTabs.ViewModel.Impl.Tab { get set }
            var chatsListViewModel: Chats.List.ViewModel.Impl { get }
            var settingsViewModel: Settings.ViewModel.Impl { get }

            func selectTab(_ tab: AppTabs.ViewModel.Impl.Tab)
            func reset()

        } // Interface

    } // ViewModel

} // AppTabs
