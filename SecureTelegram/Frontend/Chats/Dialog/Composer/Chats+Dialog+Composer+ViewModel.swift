//
//  Chats+Dialog+Composer+ViewModel.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import Foundation
import Combine

extension Chats.Dialog.Composer {

    struct ViewModel {

        @MainActor
        protocol Interface: ObservableObject {

            var action: Chats.Dialog.Composer.ViewModel.Impl.Action? { get set }
            var text: String { get set }
            var attachments: [Chats.Dialog.Attachment] { get }
            var isSending: Bool { get }
            var errorMessage: String? { get }
            var canSend: Bool { get }

            func configure(chatID: Int64)
            func appendPickedImages(_ items: [Chats.Dialog.Composer.PickedImagePayload]) async
            func removeAttachment(id: UUID)
            func send() async
            func consumeAction()

        } // Interface

    } // ViewModel

} // Chats.Dialog.Composer
