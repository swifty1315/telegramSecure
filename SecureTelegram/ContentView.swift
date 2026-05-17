//
//  ContentView.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var authorizationViewModel: Authorization.ViewModel.Impl

    init(authorizationViewModel: Authorization.ViewModel.Impl) {

        _authorizationViewModel = StateObject(wrappedValue: authorizationViewModel)
    }

    var body: some View {

        Group {
            if authorizationViewModel.phase == .authorized {
                AppTabs.View(viewModel: authorizationViewModel.appTabsViewModel)
            } else {
                NavigationStack {
                    Authorization.View(viewModel: authorizationViewModel)
                }
            }
        }
        .task {
            authorizationViewModel.onAppear()
        }
        .onChange(of: authorizationViewModel.chatsListViewModel.hasAuthorizationExpired) { _, hasAuthorizationExpired in
            guard hasAuthorizationExpired else {
                return
            }

            authorizationViewModel.handleAuthorizationExpired()
        }
    }
}

#Preview {
    ContentView(
        authorizationViewModel: AppDependency.resolveAuthorizationViewModel(
            from: AppDependency.makeContainer()
        )
    )
}
