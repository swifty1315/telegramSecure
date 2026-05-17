//
//  Chats.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

struct Chats {

    struct Factory {

        static func register(with container: Container) {

            Chats.List.Controller.Factory.register(with: container)
            Chats.Dialog.Controller.Factory.register(with: container)

            let resolver = container.synchronize()

            container.register(Chats.List.ViewModel.Impl.self) { _ in
                Chats.List.ViewModel.Impl(resolver: resolver)
            }

            container.register((any Chats.List.ViewModel.Interface).self) { _ in
                Chats.List.ViewModel.Impl(resolver: resolver)
            }

            container.register(Chats.Dialog.ViewModel.Impl.self) { _ in
                Chats.Dialog.ViewModel.Impl(resolver: resolver)
            }

            container.register((any Chats.Dialog.ViewModel.Interface).self) { _ in
                Chats.Dialog.ViewModel.Impl(resolver: resolver)
            }

            container.register(Chats.Dialog.Composer.ViewModel.Impl.self) { _ in
                Chats.Dialog.Composer.ViewModel.Impl(resolver: resolver)
            }

            container.register((any Chats.Dialog.Composer.ViewModel.Interface).self) { _ in
                Chats.Dialog.Composer.ViewModel.Impl(resolver: resolver)
            }
        }

    } // Factory

} // Chats
