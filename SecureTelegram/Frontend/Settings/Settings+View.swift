//
//  Settings+View.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import SwiftUI
import Combine

extension Settings {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Settings.ViewModel.Impl
        @StateObject private var router = Settings.Router()

        var body: some SwiftUI.View {

            List {
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            Button {
                                viewModel.didTapRow(row)
                            } label: {
                                rowView(row)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(viewModel.navigationTitle)
            .onReceive(viewModel.$action.compactMap { $0 }) { action in
                switch action {
                case .openDialogsEncryption:
                    router.route = .dialogsEncryption
                }

                viewModel.consumeAction()
            }
            .navigationDestination(item: $router.route) { route in
                switch route {
                case .dialogsEncryption:
                    Settings.DialogsEncryption.View(viewModel: viewModel.dialogsEncryptionViewModel)
                }
            }
        }

        private func rowView(_ row: Settings.ViewModel.Impl.Row) -> some SwiftUI.View {

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.text)

                    Text(row.subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
            }
            .padding(.vertical, 4)
        }

    } // View

} // Settings
