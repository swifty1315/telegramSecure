//
//  Chats+Dialog+Composer+View.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import SwiftUI
import PhotosUI
import UIKit

extension Chats.Dialog.Composer {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Chats.Dialog.Composer.ViewModel.Impl
        @State private var selectedPhotoItems: [PhotosPickerItem] = []

        var body: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 10) {
                if viewModel.attachments.isEmpty == false {
                    attachmentsStrip
                }

                HStack(alignment: .bottom, spacing: 10) {
                    attachmentButton
                    inputBar
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .onChange(of: selectedPhotoItems) { _, newValue in
                Task {
                    await handlePickedItems(newValue)
                }
            }
        }

        private var attachmentButton: some SwiftUI.View {

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 8,
                matching: .images
            ) {
                Image(systemName: "paperclip")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 46, height: 46)
                    .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
        }

        private var inputBar: some SwiftUI.View {

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message", text: $viewModel.text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.leading, 16)
                    .padding(.trailing, showsSendButton ? 2 : 16)
                    .padding(.vertical, 12)

                if showsSendButton {
                    sendButton
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .padding(.trailing, 6)
                        .padding(.bottom, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .animation(.easeInOut(duration: 0.2), value: showsSendButton)
        }

        private var sendButton: some SwiftUI.View {

            Button {
                Task {
                    await viewModel.send()
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(viewModel.canSend ? Color.registrationGradient2 : Color.secondaryText)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.canSend == false || viewModel.isSending)
        }

        private var attachmentsStrip: some SwiftUI.View {

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.attachments) { attachment in
                        ZStack(alignment: .topTrailing) {
                            previewImage(for: attachment)

                            Button {
                                viewModel.removeAttachment(id: attachment.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white, .black.opacity(0.65))
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }

        private var showsSendButton: Bool {

            let hasText = viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            return hasText || viewModel.attachments.isEmpty == false
        }

        private func previewImage(
            for attachment: Chats.Dialog.Attachment
        ) -> some SwiftUI.View {

            Group {
                if let image = UIImage(data: attachment.previewData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        private func handlePickedItems(_ items: [PhotosPickerItem]) async {

            guard items.isEmpty == false else {
                return
            }

            var payloads: [Chats.Dialog.Composer.PickedImagePayload] = []

            for item in items.prefix(8) {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    continue
                }

                let preparedData = image.jpegData(compressionQuality: 0.92) ?? data
                payloads.append(
                    .init(
                        data: preparedData,
                        width: Int(image.size.width),
                        height: Int(image.size.height)
                    )
                )
            }

            selectedPhotoItems = []
            await viewModel.appendPickedImages(payloads)
        }

    } // View

} // Chats.Dialog.Composer
