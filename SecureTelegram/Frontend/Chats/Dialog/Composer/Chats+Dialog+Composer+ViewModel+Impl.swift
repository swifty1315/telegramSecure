//
//  Chats+Dialog+Composer+ViewModel+Impl.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine
import UIKit
import Swinject

extension Chats.Dialog.Composer.ViewModel {

    @MainActor
    final class Impl: Interface {

        enum Action: Equatable {

            case didSend
            case showError

        } // Action

        init(resolver: Resolver) {

            self.controller = resolver.resolve(Chats.Dialog.Controller.Interface.self)!
        }

        @Published var action: Action?
        @Published var text = ""
        @Published private(set) var attachments: [Chats.Dialog.Attachment] = []
        @Published private(set) var isSending = false
        @Published private(set) var errorMessage: String?

        var canSend: Bool {

            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                || attachments.isEmpty == false
        }

        func configure(chatID: Int64) {

            self.chatID = chatID
        }

        func appendPickedImages(_ items: [Chats.Dialog.Composer.PickedImagePayload]) async {

            guard items.isEmpty == false else {
                return
            }

            for item in items {
                do {
                    let preparedData = item.data
                    let fileURL = temporaryFileURL()
                    try preparedData.write(
                        to: fileURL,
                        options: Data.WritingOptions.atomic
                    )

                    attachments.append(
                        .init(
                            id: UUID(),
                            localPath: fileURL.path,
                            width: item.width,
                            height: item.height,
                            previewData: preparedData
                        )
                    )
                } catch {
                    errorMessage = makeErrorMessage(from: error)
                    action = .showError
                }
            }
        }

        func removeAttachment(id: UUID) {

            attachments.removeAll { $0.id == id }
        }

        func send() async {

            guard chatID != 0 else {
                return
            }

            guard canSend else {
                return
            }

            isSending = true
            errorMessage = nil
            defer { isSending = false }

            do {
                try await controller.sendMessage(
                    chatID: chatID,
                    text: text,
                    imageAttachments: attachments
                )

                clearComposer()
                action = .didSend
            } catch {
                errorMessage = makeErrorMessage(from: error)
                action = .showError
            }
        }

        func consumeAction() {

            action = nil
        }

        private let controller: any Chats.Dialog.Controller.Interface
        private var chatID: Int64 = 0

        private func clearComposer() {

            for attachment in attachments {
                try? FileManager.default.removeItem(atPath: attachment.localPath)
            }

            text = ""
            attachments = []
        }

        private func temporaryFileURL() -> URL {

            FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
        }

        private func makeErrorMessage(from error: Swift.Error) -> String {

            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               description.isEmpty == false {
                return description
            }

            return error.localizedDescription
        }

    } // Impl

} // Chats.Dialog.Composer.ViewModel
