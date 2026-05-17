//
//  AppConfiguration.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum AppConfiguration {

    enum Networking {

        static let scheme = "https"
        static let baseHost = "your-backend-host"

    } // Networking

    enum Telegram {

        static let apiID: Int? = 39272554
        static let apiHash: String? = "ee5c85d81715afb17c87c55ade0a6166"
        static let useTestDataCenter = false
        static let useFileDatabase = true
        static let useChatInfoDatabase = true
        static let useMessageDatabase = true
        static let useSecretChats = true
        static let systemLanguageCode = Locale.preferredLanguages.first ?? "en"
        static let deviceModel = {
#if canImport(UIKit)
            UIDevice.current.model
#else
            "Apple Device"
#endif
        }()
        static let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        static let applicationVersion = "1.0"
        static let botToken: String? = nil
        static let botUsername: String? = nil
        static let webLoginClientID: String? = nil
        static let webLoginClientSecret: String? = nil

    } // Telegram

} // AppConfiguration
