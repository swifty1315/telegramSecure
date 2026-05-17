//
//  Chats+Dialog.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation

extension Chats {

    struct Dialog {

        struct Composer {}

        struct Attachment: Identifiable, Equatable {

            let id: UUID
            let localPath: String
            let width: Int
            let height: Int
            let previewData: Data

        } // Attachment

    }

} // Chats
