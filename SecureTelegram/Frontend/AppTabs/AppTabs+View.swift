//
//  AppTabs+View.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import SwiftUI

extension AppTabs {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: AppTabs.ViewModel.Impl
        @StateObject private var coordinator = Tabbar.Coordinator.Impl()

        var body: some SwiftUI.View {

            TabView(selection: selectedTabBinding) {
                NavigationStack {
                    Chats.List.View(viewModel: viewModel.chatsListViewModel)
                }
                .tabItem {
                    Label("Chats", systemImage: "message")
                }
                .tag(AppTabs.ViewModel.Impl.Tab.chats)

                NavigationStack {
                    Settings.View(viewModel: viewModel.settingsViewModel)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTabs.ViewModel.Impl.Tab.settings)
            }
            .toolbar(
                coordinator.isTabbarVisible ? .visible : .hidden,
                for: .tabBar
            )
            .environmentObject(coordinator)
        }

        private var selectedTabBinding: Binding<AppTabs.ViewModel.Impl.Tab> {

            .init(
                get: { viewModel.selectedTab },
                set: { viewModel.selectTab($0) }
            )
        }

    } // View

} // AppTabs
