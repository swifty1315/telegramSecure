//
//  AppDependency.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

struct AppDependency {

    static func makeContainer() -> Container {

        let container = Container()

        Storage.Factory.register(with: container)
        TelegramClient.Factory.register(with: container)
        Networking.Factory.register(with: container)
        Authorization.Factory.register(with: container)
        Chats.Factory.register(with: container)
        Settings.Factory.register(with: container)
        AppTabs.Factory.register(with: container)

        return container
    }

    static func resolveNetworkingController(
        from container: Container
    ) -> any Networking.Controller.Interface {

        guard let controller = container.resolve(Networking.Controller.Interface.self) else {
            fatalError("Networking.Controller.Interface is not registered.")
        }

        return controller
    }

    static func resolveAuthorizationController(
        from container: Container
    ) -> any Authorization.Controller.Interface {

        guard let controller = container.resolve(Authorization.Controller.Interface.self) else {
            fatalError("Authorization.Controller.Interface is not registered.")
        }

        return controller
    }

    static func resolveAuthorizationViewModel(
        from container: Container
    ) -> Authorization.ViewModel.Impl {

        guard let viewModel = container.resolve(Authorization.ViewModel.Impl.self) else {
            fatalError("Authorization.ViewModel.Impl is not registered.")
        }

        return viewModel
    }

    static func resolveChatsListViewModel(
        from container: Container
    ) -> Chats.List.ViewModel.Impl {

        guard let viewModel = container.resolve(Chats.List.ViewModel.Impl.self) else {
            fatalError("Chats.List.ViewModel.Impl is not registered.")
        }

        return viewModel
    }

    static func resolveTelegramClientController(
        from container: Container
    ) -> any TelegramClient.Controller.Interface {

        guard let controller = container.resolve(TelegramClient.Controller.Interface.self) else {
            fatalError("TelegramClient.Controller.Interface is not registered.")
        }

        return controller
    }

    static func prepareStorage(from container: Container) {

        guard let telegramRuntime = container.resolve(Storage.TelegramRuntime.Interface.self) else {
            fatalError("Storage.TelegramRuntime.Interface is not registered.")
        }

        do {
            try telegramRuntime.prepare()
        } catch {
            fatalError("Failed to prepare storage: \(error)")
        }
    }

} // AppDependency
