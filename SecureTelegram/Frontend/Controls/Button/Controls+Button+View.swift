//
//  Controls+Button+View.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI

extension Controls.Button {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Controls.Button.ViewModel

        var body: some SwiftUI.View {

            switch viewModel.style {
            case .primary:
                Button(viewModel.title) {
                    viewModel.action?()
                }

                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isDisabled)

            case .secondary:
                Button(viewModel.title) {
                    viewModel.action?()
                }

                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isDisabled)
            }
        }

    } // View

} // Controls.Button
