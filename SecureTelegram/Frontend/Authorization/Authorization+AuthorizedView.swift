//
//  Authorization+AuthorizedView.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI

extension Authorization {

    struct AuthorizedView: SwiftUI.View {

        @ObservedObject var viewModel: Authorization.ViewModel.Impl

        var body: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 20) {

                Text(viewModel.authorizedTitle)

                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(viewModel.authorizedScreenSubtitle)

                    .font(.body)
                    .foregroundStyle(Color.secondaryText)

                VStack(alignment: .leading, spacing: 10) {

                    Text(viewModel.authorizedUser?.phoneNumber ?? viewModel.noPhoneTitle)

                        .font(.body.monospacedDigit())
                        .foregroundStyle(Color.text)

                    if let username = viewModel.authorizedUser?.username, username.isEmpty == false {
                        Text("@\(username)")

                            .foregroundStyle(Color.secondaryText)
                    }
                }

                Controls.Button.View(viewModel: viewModel.secondaryButtonViewModel)
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
            .background(Color(.systemBackground))
            .navigationTitle(viewModel.authorizedNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }

    } // AuthorizedView

} // Authorization
