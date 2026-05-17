//
//  Chats+Dialog.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation

extension Chats.Dialog {

    struct Message: Identifiable, Codable, Equatable {

        let id: Int64
        let chatID: Int64
        let text: String
        let imageLocalPath: String?
        let imageWidth: Int?
        let imageHeight: Int?
        let sentAt: Int
        let isOutgoing: Bool

    } // Message

} // Chats.Dialog
