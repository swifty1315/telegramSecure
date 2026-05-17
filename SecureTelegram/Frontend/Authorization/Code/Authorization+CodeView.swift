//
//  Authorization+CodeView.swift
//  SecureTelegram
//
//  Created by Codex on 11.05.2026.
//

import SwiftUI
import Combine

extension Authorization {

    struct CodeView: SwiftUI.View {

        @ObservedObject var viewModel: Authorization.ViewModel.Impl
        @ObservedObject var router: Authorization.Router

        var body: some SwiftUI.View {

            VStack(spacing: 28) {

                header
                form
                footer
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(background)
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

                case .code:
                    Controls.TextField.View(viewModel: viewModel.codeFieldViewModel)

                case .password:
                    Controls.TextField.View(viewModel: viewModel.passwordFieldViewModel)

                default:
                    EmptyView()
                }
            }
        }

        private var footer: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 14) {
                Controls.Button.View(viewModel: viewModel.primaryButtonViewModel)
                Controls.Button.View(viewModel: viewModel.secondaryButtonViewModel)
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

    } // CodeView

} // Authorization
