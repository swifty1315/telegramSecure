//
//  Chats+List.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation

extension Chats.List {

    struct Item: Identifiable, Codable, Equatable {

        enum Kind: String, Codable, Equatable {

            case privateDialog
            case group
            case other

        } // Kind

        let id: Int64
        let title: String
        let preview: String
        let avatarLocalPath: String?
        let kind: Kind
        let unreadCount: Int
        let lastMessageDate: Int

    } // Item

} // Chats.List
