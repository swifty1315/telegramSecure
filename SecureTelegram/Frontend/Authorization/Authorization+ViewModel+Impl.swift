//
//  Authorization+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine
import UIKit
import Swinject
#if canImport(TDLibKit)
import TDLibKit
#endif

extension Authorization.ViewModel {

    @MainActor
    final class Impl: Interface {

        struct Alert: Equatable {

            let title: String
            let message: String
            let dismissButtonTitle: String

            static let empty = Alert(
                title: "",
                message: "",
                dismissButtonTitle: ""
            )

        } // Alert

        enum Action: Equatable {

            case showAlert
            case openCode
            case closeCode
            case openChatsList
            case closeChatsList

        } // Action

        enum Phase: Equatable {

            case booting
            case phoneNumber
            case code
            case password
            case authorized
            case unavailable

        } // Phase

        init(resolver: Resolver) {

            let resetButtonTitle = "Use Another Number"

            self.authorizationController = resolver.resolve(Authorization.Controller.Interface.self)!
            self.appTabsViewModel = resolver.resolve(AppTabs.ViewModel.Impl.self)!
            self.chatsListViewModel = resolver.resolve(Chats.List.ViewModel.Impl.self)!
            self.primaryButtonViewModel = Controls.Button.ViewModel(
                title: "",
                style: .primary
            )
            self.secondaryButtonViewModel = Controls.Button.ViewModel(
                title: resetButtonTitle,
                style: .secondary
            )
            self.phoneFieldViewModel = Controls.TextField.ViewModel(
                placeholder: "+380...",
                text: "+",
                keyboardType: .phonePad,
                textContentType: .telephoneNumber
            )
            self.codeFieldViewModel = Controls.TextField.ViewModel(
                placeholder: "Telegram code",
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
            self.passwordFieldViewModel = Controls.TextField.ViewModel(
                placeholder: "Telegram 2FA password",
                kind: .secure
            )

            bindChildViewModels()
            configureControls()
            syncChildFieldsFromParent()
        }

        @Published var action: Action?
        @Published var alert: Alert = .empty
        @Published var phase: Phase = .booting
        @Published var phoneNumber: String = "+"
        @Published var code: String = ""
        @Published var password: String = ""
        @Published private(set) var isProcessing = false
        @Published private(set) var authorizedUser: Authorization.User?

        let appTabsViewModel: AppTabs.ViewModel.Impl
        let chatsListViewModel: Chats.List.ViewModel.Impl
        let primaryButtonViewModel: Controls.Button.ViewModel
        let secondaryButtonViewModel: Controls.Button.ViewModel
        let phoneFieldViewModel: Controls.TextField.ViewModel
        let codeFieldViewModel: Controls.TextField.ViewModel
        let passwordFieldViewModel: Controls.TextField.ViewModel

        var screenTitle: String {

            "Secure Telegram"
        }

        var title: String {

            switch phase {
            case .booting:
                return "Preparing Telegram"
            case .phoneNumber:
                return "Enter your phone"
            case .code:
                return "Enter the code"
            case .password:
                return "Two-step verification"
            case .authorized:
                return "Authorization completed"
            case .unavailable:
                return "Authorization unavailable"
            }
        }

        var subtitle: String {

            switch phase {
            case .booting:
                return "TDLib is initializing local storage and authorization state."
            case .phoneNumber:
                return "Use your Telegram phone number in international format."
            case .code:
                return "Telegram has sent a login code to your account."
            case .password:
                return "This account requires your Telegram two-step verification password."
            case .authorized:
                return "@\(authorizedUser?.username ?? "telegram") is ready for the next screen."
            case .unavailable:
                return "Check Telegram app configuration and try again."
            }
        }

        var buttonTitle: String {

            switch phase {
            case .booting:
                return "Preparing"
            case .phoneNumber:
                return "Send Code"
            case .code:
                return "Confirm Code"
            case .password:
                return "Confirm Password"
            case .authorized:
                return "Authorized"
            case .unavailable:
                return "Retry"
            }
        }

        var resetButtonTitle: String {

            "Use Another Number"
        }

        var authorizedTitle: String {

            "Authorized"
        }

        var authorizedNavigationTitle: String {

            "Telegram Session"
        }

        var authorizedScreenSubtitle: String {

            "Authorization succeeded. The secured Telegram session is ready for the next module."
        }

        var noPhoneTitle: String {

            "No phone"
        }

        var initializationFailedTitle: String {

            "TDLib initialization failed"
        }

        var initializationFailedMessage: String {

            "Check package resolution, app configuration and local storage access."
        }

        var canSubmit: Bool {

            switch phase {
            case .booting:
                return false
            case .phoneNumber:
                return phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
            case .code:
                return code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            case .password:
                return password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            case .authorized:
                return false
            case .unavailable:
                return true
            }
        }

        func onAppear() {

            guard didInitialize == false else {
                return
            }

            didInitialize = true

            Task {
                await performInitialization()
            }
        }

        func didTapContinue() {

            guard isProcessing == false else {
                return
            }

            Task {
                await performPrimaryAction()
            }
        }

        func didTapReset() {

            let shouldCloseAuthorizedRoute = phase == .authorized
            let shouldCloseCodeRoute = phase == .code || phase == .password

            guard isProcessing == false else {
                return
            }

            code = ""
            password = ""
            authorizedUser = nil
            phase = .phoneNumber
            syncChildFieldsFromParent()
            configureControls()

            if shouldCloseAuthorizedRoute {
                action = .closeChatsList
            } else if shouldCloseCodeRoute {
                action = .closeCode
            }
        }

        func didCloseCodeRoute() {

            guard phase == .code || phase == .password else {
                return
            }

            code = ""
            password = ""
            phase = .phoneNumber
            syncChildFieldsFromParent()
            configureControls()
        }

        func handleAuthorizationExpired() {

            appTabsViewModel.reset()
            authorizedUser = nil
            code = ""
            password = ""
            phase = .phoneNumber
            syncChildFieldsFromParent()
            configureControls()
        }

        func consumeAction() {

            action = nil
        }

        func dismissAlert() {

            alert = .empty
        }

        private let authorizationController: any Authorization.Controller.Interface
        private var cancellables = Set<AnyCancellable>()

        private var didInitialize = false

        private func performInitialization() async {

                await runRequest {
                    let state = try await self.authorizationController.initialize()
                    self.apply(state)
                }
            }

        private func performPrimaryAction() async {

            switch phase {
            case .phoneNumber:
                await runRequest {
                    let state = try await self.authorizationController.sendCode(to: self.phoneNumber)
                    self.apply(state)
                }

            case .code:
                await runRequest {
                    let state = try await self.authorizationController.confirmCode(self.code)
                    self.apply(state)
                }

            case .password:
                await runRequest {
                    let state = try await self.authorizationController.confirmPassword(self.password)
                    self.apply(state)
                }

            case .unavailable:
                phase = .booting
                await performInitialization()

            case .booting, .authorized:
                break
            }
        }

        private func runRequest(_ operation: @escaping () async throws -> Void) async {

            isProcessing = true
            configureControls()
            defer { isProcessing = false }
            defer { configureControls() }

            do {
                try await operation()
            } catch {
                if phase == .booting {
                    phase = .unavailable
                }

                configureControls()
                alert = .init(
                    title: phase == .unavailable ? initializationFailedTitle : "Authorization Error",
                    message: makeErrorMessage(from: error),
                    dismissButtonTitle: "OK"
                )
                action = .showAlert
            }
        }

        private func apply(_ state: Authorization.State) {

            switch state {
            case .waitPhoneNumber:
                phase = .phoneNumber
                code = ""
                password = ""
                authorizedUser = nil

            case .waitCode(let phoneNumber):
                phase = .code
                if let phoneNumber {
                    self.phoneNumber = phoneNumber
                }
                password = ""
                action = .openCode

            case .waitPassword:
                phase = .password
                action = .openCode

            case .ready(let session):
                phase = .authorized
                authorizedUser = session.user
                code = ""
                password = ""
                action = .openChatsList

            case .loggingOut, .closed:
                phase = .phoneNumber
                authorizedUser = nil
                code = ""
                password = ""
            }

            syncChildFieldsFromParent()
            configureControls()
        }

        private func bindChildViewModels() {

            phoneFieldViewModel.$text
                .dropFirst()
                .sink { [weak self] text in
                    guard let self, self.phoneNumber != text else {
                        return
                    }

                    self.phoneNumber = text
                    self.configureControls()
                }
                .store(in: &cancellables)

            codeFieldViewModel.$text
                .dropFirst()
                .sink { [weak self] text in
                    guard let self, self.code != text else {
                        return
                    }

                    self.code = text
                    self.configureControls()
                }
                .store(in: &cancellables)

            passwordFieldViewModel.$text
                .dropFirst()
                .sink { [weak self] text in
                    guard let self, self.password != text else {
                        return
                    }

                    self.password = text
                    self.configureControls()
                }
                .store(in: &cancellables)
        }

        private func configureControls() {

            primaryButtonViewModel.title = buttonTitle
            primaryButtonViewModel.isDisabled = canSubmit == false || isProcessing
            primaryButtonViewModel.action = { [weak self] in
                self?.didTapContinue()
            }

            secondaryButtonViewModel.isDisabled = isProcessing
            secondaryButtonViewModel.title = resetButtonTitle
            secondaryButtonViewModel.action = { [weak self] in
                self?.didTapReset()
            }
        }

        private func syncChildFieldsFromParent() {

            if phoneFieldViewModel.text != phoneNumber {
                phoneFieldViewModel.text = phoneNumber
            }

            if codeFieldViewModel.text != code {
                codeFieldViewModel.text = code
            }

            if passwordFieldViewModel.text != password {
                passwordFieldViewModel.text = password
            }
        }

        private func makeErrorMessage(from error: Swift.Error) -> String {

#if canImport(TDLibKit)
            if let error = error as? TDLibKit.Error {
                return makeTDLibErrorMessage(from: error)
            }
#endif

            if let localizedError = error as? LocalizedError,
               let message = localizedError.errorDescription,
               message.isEmpty == false {
                return message
            }

            return error.localizedDescription
        }

#if canImport(TDLibKit)
        private func makeTDLibErrorMessage(from error: TDLibKit.Error) -> String {

            switch error.message {
            case "PASSWORD_HASH_INVALID":
                return "Incorrect Telegram two-step verification password."
            case "PHONE_CODE_INVALID":
                return "Incorrect Telegram code."
            case "PHONE_CODE_EXPIRED":
                return "Telegram code expired. Request a new code."
            case "SESSION_PASSWORD_NEEDED":
                return "This account requires a Telegram two-step verification password."
            default:
                return error.message
            }
        }
#endif

    } // Impl

} // Authorization.ViewModel
