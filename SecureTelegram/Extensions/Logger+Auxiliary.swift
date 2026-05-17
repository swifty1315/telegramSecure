//
//  Logger+Auxiliary.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import OSLog

extension Logger {

    static let authorization = Logger(category: "Authorization")
    static let telegramClient = Logger(category: "TelegramClient")
    static let storage = Logger(category: "Storage")
    static let chats = Logger(category: "Chats")

    init(category: String) {

        self = .init(subsystem: Self.subsystem, category: category)
    }

    private static var subsystem: String {

        Bundle.main.bundleIdentifier ?? "SecureTelegram"
    }

} // Logger
