//
//  Settings.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Swinject

struct Settings {

    struct Factory {

        static func register(with container: Container) {

            let resolver = container.synchronize()

            container.register(Settings.ViewModel.Impl.self) { _ in
                Settings.ViewModel.Impl(resolver: resolver)
            }

            container.register((any Settings.ViewModel.Interface).self) { _ in
                Settings.ViewModel.Impl(resolver: resolver)
            }

            container.register(Settings.DialogsEncryption.ViewModel.Impl.self) { _ in
                Settings.DialogsEncryption.ViewModel.Impl(resolver: resolver)
            }

            container.register((any Settings.DialogsEncryption.ViewModel.Interface).self) { _ in
                Settings.DialogsEncryption.ViewModel.Impl(resolver: resolver)
            }

            container.register(Settings.DialogsEncryption.Setup.ViewModel.Impl.self) { _ in
                Settings.DialogsEncryption.Setup.ViewModel.Impl(resolver: resolver)
            }

            container.register((any Settings.DialogsEncryption.Setup.ViewModel.Interface).self) { _ in
                Settings.DialogsEncryption.Setup.ViewModel.Impl(resolver: resolver)
            }
        }

    } // Factory

} // Settings
