//
//  AppTabs.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Swinject

struct AppTabs {

    struct Factory {

        static func register(with container: Container) {

            let resolver = container.synchronize()

            container.register(AppTabs.ViewModel.Impl.self) { _ in
                AppTabs.ViewModel.Impl(resolver: resolver)
            }

            container.register((any AppTabs.ViewModel.Interface).self) { _ in
                AppTabs.ViewModel.Impl(resolver: resolver)
            }
        }

    } // Factory

} // AppTabs
