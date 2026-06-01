//
//  Settings+DialogsEncryption+Setup+View.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import SwiftUI

extension Settings.DialogsEncryption.Setup {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Settings.DialogsEncryption.Setup.ViewModel.Impl

        var body: some SwiftUI.View {

            Group {
                if viewModel.records.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.addKey()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add key")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                }
            }
        }

        private var listView: some SwiftUI.View {

            List {
                ForEach(viewModel.records) { record in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            readOnlyField(
                                title: "Key",
                                value: record.key
                            )

                            readOnlyField(
                                title: "Encryption Type",
                                value: record.encryptionType
                            )

                            if viewModel.isActiveRecord(record) {
                                Controls.Button.View(viewModel: viewModel.terminateEncryptionButtonViewModel)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Encryption Key")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.text)

                            Text(subtitle(for: record))
                                .font(.footnote)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }

        private var emptyView: some SwiftUI.View {

            VStack(spacing: 14) {
                Image(systemName: "key.slash")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.secondaryText)

                Text(viewModel.emptyTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.text)
                    .multilineTextAlignment(.center)

                Controls.Button.View(viewModel: viewModel.addKeyButtonViewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }

        private func readOnlyField(
            title: String,
            value: String
        ) -> some SwiftUI.View {

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)

                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }

        private func subtitle(
            for record: Settings.DialogsEncryption.Setup.ViewModel.KeyRecord
        ) -> String {

            let from = Self.dateFormatter.string(from: record.appliedFrom)
            let to = record.appliedTo.map { Self.dateFormatter.string(from: $0) } ?? "Now"

            return "\(from) - \(to)"
        }

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter
        }()

    } // View

} // Settings.DialogsEncryption.Setup
