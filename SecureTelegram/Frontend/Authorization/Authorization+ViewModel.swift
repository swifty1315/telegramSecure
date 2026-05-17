//
//  Authorization+ViewModel.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Swinject

extension Authorization {

    struct ViewModel {

        @MainActor
        protocol Interface: ObservableObject {

            var action: Authorization.ViewModel.Impl.Action? { get set }
            var alert: Authorization.ViewModel.Impl.Alert { get }
            var appTabsViewModel: AppTabs.ViewModel.Impl { get }
            var chatsListViewModel: Chats.List.ViewModel.Impl { get }
            var phase: Authorization.ViewModel.Impl.Phase { get }
            var phoneNumber: String { get set }
            var code: String { get set }
            var password: String { get set }
            var isProcessing: Bool { get }
            var screenTitle: String { get }
            var title: String { get }
            var subtitle: String { get }
            var buttonTitle: String { get }
            var resetButtonTitle: String { get }
            var authorizedTitle: String { get }
            var authorizedNavigationTitle: String { get }
            var authorizedScreenSubtitle: String { get }
            var noPhoneTitle: String { get }
            var initializationFailedTitle: String { get }
            var initializationFailedMessage: String { get }
            var canSubmit: Bool { get }
            var authorizedUser: Authorization.User? { get }

            func onAppear()
            func didTapContinue()
            func didTapReset()
            func didCloseCodeRoute()
            func handleAuthorizationExpired()
            func dismissAlert()
            func consumeAction()

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                let resolver = container.synchronize()

                container.register(Impl.self) { _ in
                    Impl(resolver: resolver)
                }

                container.register((any Interface).self) { _ in
                    Impl(resolver: resolver)
                }
            }

        } // Factory

    } // ViewModel

} // Authorization
