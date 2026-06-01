//
//  Chats+Dialog+Event.swift
//  SecureTelegram
//
//  Created by Codex on 17.05.2026.
//

import Foundation

extension Chats.Dialog {

    enum Event: Equatable {

        case messageInserted(Chats.Dialog.Message)
        case messageUpdated(Chats.Dialog.Message)
        case messagesDeleted(chatID: Int64, messageIDs: [Int64])
        case refreshRequired(chatID: Int64)

    } // Event

} // Chats.Dialog
