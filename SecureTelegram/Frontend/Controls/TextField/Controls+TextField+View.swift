//
//  Controls+TextField+View.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI

extension Controls.TextField {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Controls.TextField.ViewModel

        var body: some SwiftUI.View {

            HStack(spacing: 0) {

                field
            }

            .frame(height: 44)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground), in: Capsule())
        }

        @ViewBuilder
        private var field: some SwiftUI.View {

            switch viewModel.kind {
            case .regular:
                SwiftUI.TextField(viewModel.placeholder, text: $viewModel.text)

                    .keyboardType(viewModel.keyboardType)
                    .textContentType(viewModel.textContentType)
                    .foregroundStyle(Color.text)

            case .secure:
                SecureField(viewModel.placeholder, text: $viewModel.text)

                    .textContentType(viewModel.textContentType)
                    .foregroundStyle(Color.text)
            }
        }

    } // View

} // Controls.TextField
