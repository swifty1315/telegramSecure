//
//  Authorization+View.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI
import Combine

extension Authorization {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Authorization.ViewModel.Impl
        @StateObject private var router = Authorization.Router()

        init(viewModel: Authorization.ViewModel.Impl) {

            self.viewModel = viewModel
        }

        var body: some SwiftUI.View {

            VStack(spacing: 28) {

                header
                form
                footer
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background)
            .task {
                viewModel.onAppear()
            }
            .onReceive(viewModel.$action.compactMap { $0 }) { action in
                switch action {
                case .showAlert:
                    router.node = .alert
                case .openCode:
                    router.route = .code
                case .closeCode:
                    if router.route == .code {
                        router.route = nil
                    }
                case .openChatsList, .closeChatsList:
                    break
                }

                viewModel.consumeAction()
            }
            .onChange(of: router.route) { _, route in
                if route == nil {
                    viewModel.didCloseCodeRoute()
                }
            }
            .navigationDestination(item: $router.route) { route in
                switch route {
                case .code:
                    Authorization.CodeView(
                        viewModel: viewModel,
                        router: router
                    )
                case .chatsList:
                    EmptyView()
                }
            }
            .alert(viewModel.alert.title, isPresented: router.bindNode(.alert), actions: {

                Button(viewModel.alert.dismissButtonTitle, role: .cancel) {

                    router.node = nil
                    viewModel.dismissAlert()
                }
            }, message: {

                Text(viewModel.alert.message)
            })
        }

        private var header: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 10) {

                Text(viewModel.screenTitle)

                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(viewModel.title)

                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(viewModel.subtitle)

                    .font(.body)
                    .foregroundStyle(Color.secondaryText)
            }

            .frame(maxWidth: .infinity, alignment: .leading)
        }

        @ViewBuilder
        private var form: some SwiftUI.View {

            VStack(spacing: 16) {

                switch viewModel.phase {

                case .booting:
                    ProgressView()

                        .frame(maxWidth: .infinity, alignment: .leading)
                case .phoneNumber:
                    Controls.TextField.View(viewModel: viewModel.phoneFieldViewModel)

                case .authorized:
                    EmptyView()

                case .code, .password:
                    EmptyView()

                case .unavailable:
                    unavailableCard
                }
            }
        }

        private var footer: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 14) {
                Controls.Button.View(viewModel: viewModel.primaryButtonViewModel)

                if viewModel.phase == .authorized {
                    Controls.Button.View(viewModel: viewModel.secondaryButtonViewModel)
                }
            }

            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var unavailableCard: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 10) {
                Label(viewModel.initializationFailedTitle, systemImage: "exclamationmark.triangle.fill")

                    .font(.headline)
                    .foregroundStyle(Color.appWarning)

                Text(viewModel.initializationFailedMessage)

                    .foregroundStyle(Color.secondaryText)
            }

            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var background: some SwiftUI.View {

            LinearGradient(
                colors: [
                    Color.registrationGradient1,
                    Color.registrationGradient2,
                    Color.registrationGradient3,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            .ignoresSafeArea()
        }

    } // View

} // Authorization
