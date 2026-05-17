//
//  SecureTelegramApp.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI
import Swinject

@main
struct SecureTelegramApp: App {

    private let container: Container = {
        let container = AppDependency.makeContainer()
        AppDependency.prepareStorage(from: container)

        return container
    }()

    var body: some Scene {

        WindowGroup {
            ContentView(
                authorizationViewModel: AppDependency.resolveAuthorizationViewModel(from: container)
            )
        }
    }
}
