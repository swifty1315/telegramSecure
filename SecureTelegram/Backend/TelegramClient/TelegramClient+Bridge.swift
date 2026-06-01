//
//  TelegramClient+Bridge.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import OSLog
import Swinject
#if canImport(TDLibKit)
import TDLibKit
#endif

extension TelegramClient {

    struct Bridge {

        protocol Interface {

            var authorizationState: TelegramClient.AuthorizationState { get }

            func reset() async

            func initialize(with parameters: TelegramClient.Parameters) async throws -> TelegramClient.AuthorizationState

            func setAuthenticationPhoneNumber(_ phoneNumber: String) async throws -> TelegramClient.AuthorizationState

            func checkAuthenticationCode(_ code: String) async throws -> TelegramClient.AuthorizationState

            func checkAuthenticationPassword(_ password: String) async throws -> TelegramClient.AuthorizationState

            func fetchDialogs(limit: Int) async throws -> [Chats.List.Item]

            func fetchMessageHistory(
                chatID: Int64,
                fromMessageID: Int64,
                limit: Int
            ) async throws -> [Chats.Dialog.Message]

            func messageEvents(chatID: Int64) -> AsyncStream<Chats.Dialog.Event>

            func sendMessage(
                chatID: Int64,
                text: String,
                imageAttachments: [Chats.Dialog.Attachment]
            ) async throws

        } // Interface

        struct Factory {

            static func register(with container: Container) {

                container.register(Interface.self) { _ in
                    Impl()
                }
                .inObjectScope(.container)
            }

        } // Factory

        final class Impl: Interface {

            var authorizationState: TelegramClient.AuthorizationState {

                stateQueue.sync { state }
            }

            func reset() async {

                logger.warning("*** TDLIB bridge reset requested.")

#if canImport(TDLibKit)
                if client != nil, authorizationState != .closed {
                    _ = try? await awaitAuthorizationState(
                        matching: { state in
                            if case .closed = state {
                                return true
                            }

                            return false
                        }
                    ) {
                        self.manager?.closeClients()
                    }
                }

                client = nil
#endif

                stateQueue.sync {
                    state = .waitTdlibParameters
                    pendingContinuation = nil
                    pendingStateMatcher = nil
                }

                parameters = nil
                phoneNumber = nil
            }

            func initialize(with parameters: TelegramClient.Parameters) async throws -> TelegramClient.AuthorizationState {

                guard parameters.apiHash.isEmpty == false else {
                    throw TelegramClient.Error.missingAppConfiguration
                }

                logger.info("*** TDLIB bridge initialize requested. currentState=\(self.describe(self.authorizationState), privacy: .public).")
                self.parameters = parameters

#if canImport(TDLibKit)
                let client = makeClientIfNeeded()
                let shouldConfigureClient = {
                    switch self.authorizationState {
                    case .waitTdlibParameters, .closed:
                        return true
                    default:
                        return false
                    }
                }()

                if self.authorizationState == .closed {
                    logger.warning("*** TDLIB bridge initialize detected closed state. Resetting state back to waitTdlibParameters before setTdlibParameters.")
                    setState(.waitTdlibParameters)
                }

                if shouldConfigureClient {
                    return try await awaitAuthorizationState(
                        matching: { state in
                            if case .waitTdlibParameters = state {
                                return false
                            }

                            if case .closed = state {
                                return false
                            }

                            return true
                        }
                    ) {
                        _ = try await client.setTdlibParameters(
                            apiHash: parameters.apiHash,
                            apiId: parameters.apiID,
                            applicationVersion: parameters.applicationVersion,
                            databaseDirectory: parameters.databaseDirectory,
                            databaseEncryptionKey: parameters.databaseEncryptionKey,
                            deviceModel: parameters.deviceModel,
                            filesDirectory: parameters.filesDirectory,
                            systemLanguageCode: parameters.systemLanguageCode,
                            systemVersion: parameters.systemVersion,
                            useChatInfoDatabase: parameters.useChatInfoDatabase,
                            useFileDatabase: parameters.useFileDatabase,
                            useMessageDatabase: parameters.useMessageDatabase,
                            useSecretChats: parameters.useSecretChats,
                            useTestDc: parameters.useTestDataCenter
                        )
                    }
                }

                logger.info("*** TDLIB bridge initialize returned existing state: \(self.describe(self.authorizationState), privacy: .public).")
                return self.authorizationState
#else
                setState(.waitPhoneNumber)
                logger.info("Bridge initialize stubbed to waitPhoneNumber.")
                return self.authorizationState
#endif
            }

            func setAuthenticationPhoneNumber(_ phoneNumber: String) async throws -> TelegramClient.AuthorizationState {

                guard parameters != nil else {
                    logger.error("*** TDLIB bridge setAuthenticationPhoneNumber failed. Bridge is not configured.")
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

                guard case .waitPhoneNumber = self.authorizationState else {
                    logger.error("*** TDLIB bridge setAuthenticationPhoneNumber invalid state: \(self.describe(self.authorizationState), privacy: .public).")
                    throw TelegramClient.Error.invalidState
                }

                logger.info("*** TDLIB bridge setAuthenticationPhoneNumber accepted for phone: \(self.mask(phoneNumber: phoneNumber), privacy: .public).")
                self.phoneNumber = phoneNumber

#if canImport(TDLibKit)
                let client = try requireClient()

                return try await awaitNextAuthorizationState {
                    _ = try await client.setAuthenticationPhoneNumber(
                        phoneNumber: phoneNumber,
                        settings: nil
                    )
                }
#else
                setState(.waitCode(phoneNumber: phoneNumber))
                return authorizationState
#endif
            }

            func checkAuthenticationCode(_ code: String) async throws -> TelegramClient.AuthorizationState {

                guard parameters != nil else {
                    logger.error("*** TDLIB bridge checkAuthenticationCode failed. Bridge is not configured.")
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

                guard case .waitCode = self.authorizationState else {
                    logger.error("*** TDLIB bridge checkAuthenticationCode invalid state: \(self.describe(self.authorizationState), privacy: .public).")
                    throw TelegramClient.Error.invalidState
                }

                logger.info("*** TDLIB bridge checkAuthenticationCode accepted. codeLength=\(code.count, privacy: .public).")
#if canImport(TDLibKit)
                let client = try requireClient()

                return try await awaitNextAuthorizationState {
                    _ = try await client.checkAuthenticationCode(code: code)
                }
#else
                if code == "password" {
                    setState(.waitPassword)
                } else {
                    setState(
                        .ready(
                            .init(
                                id: 0,
                                firstName: "Telegram",
                                lastName: "User",
                                username: phoneNumber,
                                phoneNumber: phoneNumber
                            )
                        )
                    )
                }

                return authorizationState
#endif
            }

            func checkAuthenticationPassword(_ password: String) async throws -> TelegramClient.AuthorizationState {

                guard parameters != nil else {
                    logger.error("*** TDLIB bridge checkAuthenticationPassword failed. Bridge is not configured.")
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

                guard case .waitPassword = self.authorizationState else {
                    logger.error("*** TDLIB bridge checkAuthenticationPassword invalid state: \(self.describe(self.authorizationState), privacy: .public).")
                    throw TelegramClient.Error.invalidState
                }

                logger.info("*** TDLIB bridge checkAuthenticationPassword accepted. passwordLength=\(password.count, privacy: .public).")
#if canImport(TDLibKit)
                let client = try requireClient()

                return try await awaitNextAuthorizationState {
                    _ = try await client.checkAuthenticationPassword(password: password)
                }
#else
                setState(
                    .ready(
                        .init(
                            id: 0,
                            firstName: "Telegram",
                            lastName: "User",
                            username: phoneNumber,
                            phoneNumber: phoneNumber
                        )
                    )
                )

                return authorizationState
#endif
            }

            func fetchDialogs(limit: Int) async throws -> [Chats.List.Item] {

                guard parameters != nil else {
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

#if canImport(TDLibKit)
                let client = try requireClient()
                let logger = self.logger
                let formatError: @Sendable (Swift.Error) -> String = { error in
                    if let error = error as? TDLibKit.Error {
                        return "[code=\(error.code)] \(error.message)"
                    }

                    if let localizedError = error as? LocalizedError,
                       let description = localizedError.errorDescription,
                       description.isEmpty == false {
                        return description
                    }

                    return error.localizedDescription
                }
                let isUnauthorized: @Sendable (Swift.Error) -> Bool = { error in
                    if let error = error as? TDLibKit.Error {
                        return error.code == 401 || error.message == "Unauthorized"
                    }

                    if let error = error as? TelegramClient.Error,
                       error == .unauthorized {
                        return true
                    }

                    return false
                }

                do {
                    _ = try await client.loadChats(
                        chatList: nil,
                        limit: max(limit, 1)
                    )
                } catch {}

                let chats = try await client.getChats(
                    chatList: nil,
                    limit: max(limit, 1)
                )

                return try await withThrowingTaskGroup(
                    of: DialogFetchResult.self,
                    returning: [Chats.List.Item].self
                ) { group in
                    for chatID in chats.chatIds {
                        group.addTask {
                            do {
                                let chat = try await client.getChat(chatId: chatID)
                                let item = try await self.makeDialogItem(
                                    from: chat,
                                    using: client
                                )
                                return DialogFetchResult(item: item, isUnauthorized: false)
                            } catch {
                                logger.error("*** TDLIB bridge failed to build dialog item for chatID=\(chatID, privacy: .public). error=\(formatError(error), privacy: .public).")
                                return DialogFetchResult(
                                    item: nil,
                                    isUnauthorized: isUnauthorized(error)
                                )
                            }
                        }
                    }

                    var items: [Chats.List.Item] = []
                    var unauthorizedFailures = 0

                    for try await result in group {
                        if let item = result.item {
                            items.append(item)
                        }

                        if result.isUnauthorized {
                            unauthorizedFailures += 1
                        }
                    }

                    if items.isEmpty, unauthorizedFailures > 0 {
                        throw TelegramClient.Error.unauthorized
                    }

                    return items.sorted {
                        if $0.lastMessageDate == $1.lastMessageDate {
                            return $0.id > $1.id
                        }

                        return $0.lastMessageDate > $1.lastMessageDate
                    }
                }
#else
                return []
#endif
            }

            func fetchMessageHistory(
                chatID: Int64,
                fromMessageID: Int64,
                limit: Int
            ) async throws -> [Chats.Dialog.Message] {

                guard parameters != nil else {
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

#if canImport(TDLibKit)
                let client = try requireClient()
                let targetCount = min(max(limit, 1), 100)
                var history: [Message] = []
                var cursor = fromMessageID
                var didStartFromLastMessage = fromMessageID == 0

                while history.count < targetCount {
                    let response = try await client.getChatHistory(
                        chatId: chatID,
                        fromMessageId: cursor,
                        limit: targetCount - history.count,
                        offset: 0,
                        onlyLocal: false
                    )

                    var chunk = response.messages ?? []

                    if didStartFromLastMessage == false,
                       let cursorMessageID = history.last?.id {
                        chunk.removeAll { $0.id == cursorMessageID }
                    }

                    guard chunk.isEmpty == false else {
                        break
                    }

                    history.append(contentsOf: chunk)
                    cursor = chunk.last?.id ?? 0
                    didStartFromLastMessage = false
                }

                var dialogMessages: [Chats.Dialog.Message] = []

                for message in history {
                    dialogMessages.append(
                        try await makeDialogMessage(
                            from: message,
                            using: client
                        )
                    )
                }

                return dialogMessages.sorted { $0.id < $1.id }
#else
                return []
#endif
            }

            func messageEvents(chatID: Int64) -> AsyncStream<Chats.Dialog.Event> {

                AsyncStream { continuation in
                    let subscriptionID = UUID()

                    eventQueue.sync {
                        messageEventContinuations[subscriptionID] = .init(
                            chatID: chatID,
                            continuation: continuation
                        )
                    }

                    continuation.onTermination = { [weak self] _ in
                        self?.removeMessageEventSubscription(subscriptionID)
                    }
                }
            }

            func sendMessage(
                chatID: Int64,
                text: String,
                imageAttachments: [Chats.Dialog.Attachment]
            ) async throws {

                guard parameters != nil else {
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

#if canImport(TDLibKit)
                let client = try requireClient()

                if imageAttachments.isEmpty {
                    let messageText = text.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard messageText.isEmpty == false else {
                        return
                    }

                    _ = try await client.sendMessage(
                        chatId: chatID,
                        inputMessageContent: .inputMessageText(
                            .init(
                                clearDraft: false,
                                linkPreviewOptions: nil,
                                text: .init(entities: [], text: messageText)
                            )
                        ),
                        options: makeDefaultSendOptions(),
                        replyMarkup: nil,
                        replyTo: nil,
                        topicId: nil
                    )

                    return
                }

                let caption = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let contents = imageAttachments.prefix(8).enumerated().map { index, attachment in
                    InputMessageContent.inputMessagePhoto(
                        .init(
                            addedStickerFileIds: [],
                            caption: index == 0 && caption.isEmpty == false
                                ? .init(entities: [], text: caption)
                                : nil,
                            hasSpoiler: false,
                            height: attachment.height,
                            photo: .inputFileLocal(.init(path: attachment.localPath)),
                            selfDestructType: nil,
                            showCaptionAboveMedia: false,
                            thumbnail: nil,
                            video: nil,
                            width: attachment.width
                        )
                    )
                }

                if contents.count == 1 {
                    _ = try await client.sendMessage(
                        chatId: chatID,
                        inputMessageContent: contents[0],
                        options: makeDefaultSendOptions(),
                        replyMarkup: nil,
                        replyTo: nil,
                        topicId: nil
                    )
                } else {
                    _ = try await client.sendMessageAlbum(
                        chatId: chatID,
                        inputMessageContents: contents,
                        options: makeDefaultSendOptions(),
                        replyTo: nil,
                        topicId: nil
                    )
                }
#else
                _ = chatID
                _ = text
                _ = imageAttachments
#endif
            }

            private var parameters: TelegramClient.Parameters?
            private var phoneNumber: String?
            private let stateQueue = DispatchQueue(label: "SecureTelegram.TelegramClient.Bridge.State")
            private var state: TelegramClient.AuthorizationState = .waitTdlibParameters
            private var pendingContinuation: CheckedContinuation<TelegramClient.AuthorizationState, Swift.Error>?
            private var pendingStateMatcher: ((TelegramClient.AuthorizationState) -> Bool)?
            private let eventQueue = DispatchQueue(label: "SecureTelegram.TelegramClient.Bridge.Events")
            private var messageEventContinuations: [UUID: MessageEventSubscription] = [:]
            private let logger = Logger.telegramClient

            private struct MessageEventSubscription {

                let chatID: Int64
                let continuation: AsyncStream<Chats.Dialog.Event>.Continuation

            } // MessageEventSubscription

#if canImport(TDLibKit)
            private var manager: TDLibClientManager?
            private var client: TDLibClient?
#endif

            private func setState(_ newState: TelegramClient.AuthorizationState) {

                stateQueue.sync {
                    state = newState
                }
            }

            private func awaitNextAuthorizationState(
                operation: @escaping () async throws -> Void
            ) async throws -> TelegramClient.AuthorizationState {

                try await awaitAuthorizationState(
                    matching: { _ in true },
                    operation: operation
                )
            }

            private func awaitAuthorizationState(
                matching matcher: @escaping (TelegramClient.AuthorizationState) -> Bool,
                operation: @escaping () async throws -> Void
            ) async throws -> TelegramClient.AuthorizationState {

                try await withCheckedThrowingContinuation { continuation in
                    stateQueue.sync {
                        pendingContinuation = continuation
                        pendingStateMatcher = matcher
                    }

                    Task {
                        do {
                            try await operation()
                        } catch {
                            self.logger.error("*** TDLIB bridge awaited operation failed: \(self.makeErrorMessage(from: error), privacy: .public).")
                            self.finishPendingContinuation(with: .failure(error))
                        }
                    }
                }
            }

            private func finishPendingContinuation(
                with result: Result<TelegramClient.AuthorizationState, Swift.Error>
            ) {

                let continuation = stateQueue.sync { () -> CheckedContinuation<TelegramClient.AuthorizationState, Swift.Error>? in
                    let continuation = pendingContinuation
                    pendingContinuation = nil
                    pendingStateMatcher = nil

                    return continuation
                }

                guard let continuation else {
                    return
                }

                switch result {
                case .success(let state):
                    continuation.resume(returning: state)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            nonisolated private func removeMessageEventSubscription(_ subscriptionID: UUID) {

                eventQueue.sync {
                    messageEventContinuations[subscriptionID] = nil
                }
            }

            private func publishMessageEvent(
                _ event: Chats.Dialog.Event,
                chatID: Int64
            ) {

                let continuations = eventQueue.sync {
                    messageEventContinuations.values
                        .filter { $0.chatID == chatID }
                        .map(\.continuation)
                }

                continuations.forEach { continuation in
                    continuation.yield(event)
                }
            }

            private func int64Value(from value: Any?) -> Int64? {

                if let value = value as? Int64 {
                    return value
                }

                if let value = value as? Int {
                    return Int64(value)
                }

                if let value = value as? NSNumber {
                    return value.int64Value
                }

                if let value = value as? String {
                    return Int64(value)
                }

                return nil
            }

            private func int64Values(from value: Any?) -> [Int64] {

                guard let values = value as? [Any] else {
                    return []
                }

                return values.compactMap { int64Value(from: $0) }
            }

#if canImport(TDLibKit)
            private func makeClientIfNeeded() -> TDLibClient {

                if let client {
                    return client
                }

                if manager == nil {
                    manager = TDLibClientManager()
                }

                let client = manager!.createClient { [weak self] data, tdClient in
                    self?.handleUpdate(data, client: tdClient)
                }

                self.client = client

                return client
            }

            private func requireClient() throws -> TDLibClient {

                guard let client else {
                    throw TelegramClient.Error.nativeBridgeNotConfigured
                }

                return client
            }

            private func isCurrent(client: TDLibClient) -> Bool {

                self.client === client
            }

            private func handleUpdate(_ data: Data, client: TDLibClient) {

                guard self.isCurrent(client: client) else {
                    logger.debug("*** TDLIB bridge ignored update from stale TDLib client.")
                    return
                }

                guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = object["@type"] as? String else {
                    return
                }

                switch type {
                case "updateAuthorizationState":
                    handleAuthorizationUpdate(object, client: client)
                case "updateNewMessage":
                    handleNewMessageUpdate(object, client: client)
                case "updateMessageContent":
                    handleMessageContentUpdate(object)
                case "updateDeleteMessages":
                    handleDeleteMessagesUpdate(object)
                default:
                    return
                }
            }

            private func handleAuthorizationUpdate(_ object: [String: Any], client: TDLibClient) {

                guard let authorizationState = object["authorization_state"] as? [String: Any],
                      let authorizationType = authorizationState["@type"] as? String else {
                    return
                }

                switch authorizationType {
                case "authorizationStateWaitTdlibParameters":
                    publish(.waitTdlibParameters)

                case "authorizationStateWaitPhoneNumber":
                    publish(.waitPhoneNumber)

                case "authorizationStateWaitCode":
                    publish(.waitCode(phoneNumber: phoneNumber))

                case "authorizationStateWaitPassword":
                    publish(.waitPassword)

                case "authorizationStateReady":
                    Task {
                        let user = await self.makeAuthorizedUser(using: client)
                        self.publish(.ready(user))
                    }

                case "authorizationStateLoggingOut":
                    publish(.loggingOut)

                case "authorizationStateClosed":
                    publish(.closed)

                default:
                    publish(.unknown(authorizationType))
                }
            }

            private func decodeMessage(from object: [String: Any]) throws -> Message {

                let data = try JSONSerialization.data(withJSONObject: object)
                return try JSONDecoder().decode(Message.self, from: data)
            }

            private func handleNewMessageUpdate(_ object: [String: Any], client: TDLibClient) {

                guard let messageObject = object["message"] as? [String: Any] else {
                    return
                }

                Task {
                    do {
                        let message = try decodeMessage(from: messageObject)
                        let dialogMessage = try await makeDialogMessage(
                            from: message,
                            using: client
                        )

                        publishMessageEvent(
                            .messageInserted(dialogMessage),
                            chatID: dialogMessage.chatID
                        )
                    } catch {
                        if let chatID = int64Value(from: messageObject["chat_id"]) {
                            publishMessageEvent(.refreshRequired(chatID: chatID), chatID: chatID)
                        }

                        logger.warning("*** TDLIB bridge failed to decode updateNewMessage: \(self.makeErrorMessage(from: error), privacy: .public).")
                    }
                }
            }

            private func handleMessageContentUpdate(_ object: [String: Any]) {

                guard let chatID = int64Value(from: object["chat_id"]) else {
                    return
                }

                publishMessageEvent(.refreshRequired(chatID: chatID), chatID: chatID)
            }

            private func handleDeleteMessagesUpdate(_ object: [String: Any]) {

                guard let chatID = int64Value(from: object["chat_id"]) else {
                    return
                }

                let messageIDs = int64Values(from: object["message_ids"])

                publishMessageEvent(
                    .messagesDeleted(chatID: chatID, messageIDs: messageIDs),
                    chatID: chatID
                )
            }

            private func makeAuthorizedUser(using client: TDLibClient) async -> TelegramClient.User? {

                for attempt in 1...3 {
                    do {
                        let user = try await client.getMe()

                        return .init(
                            id: user.id,
                            firstName: user.firstName,
                            lastName: user.lastName,
                            username: user.usernames?.activeUsernames.first,
                            phoneNumber: user.phoneNumber
                        )
                    } catch {
                        logger.warning("*** TDLIB getMe failed after ready update. attempt=\(attempt, privacy: .public) error=\(self.makeErrorMessage(from: error), privacy: .public).")

                        if attempt < 3 {
                            try? await Task.sleep(for: .milliseconds(250))
                        }
                    }
                }

                logger.error("*** TDLIB getMe failed after authorizationStateReady. Returning nil user.")
                return nil
            }

            private func publish(_ newState: TelegramClient.AuthorizationState) {

                logger.info("*** TDLIB bridge authorization update: \(self.describe(newState), privacy: .public).")
                setState(newState)

                let shouldFinish = stateQueue.sync {
                    pendingStateMatcher?(newState) ?? false
                }

                if shouldFinish {
                    finishPendingContinuation(with: .success(newState))
                }
            }

            private static func makeErrorMessage(from error: Swift.Error) -> String {

#if canImport(TDLibKit)
                if let error = error as? TDLibKit.Error {
                    return "[code=\(error.code)] \(error.message)"
                }
#endif

                if let localizedError = error as? LocalizedError,
                   let description = localizedError.errorDescription,
                   description.isEmpty == false {
                    return description
                }

                return error.localizedDescription
            }

            private func makeErrorMessage(from error: Swift.Error) -> String {

                Self.makeErrorMessage(from: error)
            }

            private static func isUnauthorizedError(_ error: Swift.Error) -> Bool {

#if canImport(TDLibKit)
                if let error = error as? TDLibKit.Error {
                    return error.code == 401 || error.message == "Unauthorized"
                }
#endif

                if let error = error as? TelegramClient.Error,
                   error == .unauthorized {
                    return true
                }

                return false
            }

            private func mask(phoneNumber: String) -> String {

                guard phoneNumber.count > 4 else {
                    return phoneNumber
                }

                return "***\(phoneNumber.suffix(4))"
            }

            private func describe(_ state: TelegramClient.AuthorizationState) -> String {

                switch state {
                case .waitTdlibParameters:
                    return "waitTdlibParameters"
                case .waitPhoneNumber:
                    return "waitPhoneNumber"
                case .waitCode(let phoneNumber):
                    return "waitCode(phone: \(mask(phoneNumber: phoneNumber ?? "")))"
                case .waitPassword:
                    return "waitPassword"
                case .ready(let user):
                    return "ready(userID: \(user?.id ?? 0))"
                case .loggingOut:
                    return "loggingOut"
                case .closed:
                    return "closed"
                case .unknown(let value):
                    return "unknown(\(value))"
                }
            }

            private func makeDialogItem(
                from chat: Chat,
                using client: TDLibClient
            ) async throws -> Chats.List.Item {

                Chats.List.Item(
                    id: chat.id,
                    title: chat.title,
                    preview: makeMessagePreview(from: chat.lastMessage?.content),
                    avatarLocalPath: try await makeAvatarLocalPath(
                        from: chat.photo,
                        using: client
                    ),
                    kind: makeDialogKind(from: chat.type),
                    unreadCount: chat.unreadCount,
                    lastMessageDate: chat.lastMessage?.date ?? 0
                )
            }

            private func makeDialogKind(from type: ChatType) -> Chats.List.Item.Kind {

                switch type {
                case .chatTypePrivate, .chatTypeSecret:
                    return .privateDialog
                case .chatTypeBasicGroup, .chatTypeSupergroup:
                    return .group
                }
            }

            private func makeDialogMessage(
                from message: Message,
                using client: TDLibClient
            ) async throws -> Chats.Dialog.Message {

                let photoResource = try await makeDialogPhotoResource(
                    from: message.content,
                    using: client
                )

                return Chats.Dialog.Message(
                    id: message.id,
                    chatID: message.chatId,
                    text: makeDialogMessageText(from: message.content),
                    imageLocalPath: photoResource?.localPath,
                    imageWidth: photoResource?.width,
                    imageHeight: photoResource?.height,
                    sentAt: message.date,
                    isOutgoing: message.isOutgoing
                )
            }

            private func makeDialogMessageText(from content: MessageContent?) -> String {

                guard let content else {
                    return ""
                }

                switch content {
                case .messagePhoto(let value):
                    return value.caption.text
                default:
                    return makeMessagePreview(from: content)
                }
            }

            private func makeMessagePreview(from content: MessageContent?) -> String {

                guard let content else {
                    return ""
                }

                switch content {
                case .messageText(let value):
                    return value.text.text
                case .messagePhoto(let value):
                    return value.caption.text.isEmpty ? "Photo" : value.caption.text
                case .messageVideo(let value):
                    return value.caption.text.isEmpty ? "Video" : value.caption.text
                case .messageDocument(let value):
                    return value.caption.text.isEmpty ? "Document" : value.caption.text
                case .messageAudio(let value):
                    return value.caption.text.isEmpty ? "Audio" : value.caption.text
                case .messageAnimation(let value):
                    return value.caption.text.isEmpty ? "Animation" : value.caption.text
                case .messageVoiceNote:
                    return "Voice message"
                case .messageSticker:
                    return "Sticker"
                case .messageCall:
                    return "Call"
                case .messagePoll:
                    return "Poll"
                case .messageLocation:
                    return "Location"
                case .messageContact:
                    return "Contact"
                default:
                    return "Unsupported message"
                }
            }

            private func makeAvatarLocalPath(
                from photo: ChatPhotoInfo?,
                using client: TDLibClient
            ) async throws -> String? {

                guard let photo else {
                    return nil
                }

                if photo.small.local.path.isEmpty == false {
                    return photo.small.local.path
                }

                do {
                    let file = try await client.downloadFile(
                        fileId: photo.small.id,
                        limit: 0,
                        offset: 0,
                        priority: 2,
                        synchronous: true
                    )

                    if file.local.path.isEmpty == false {
                        return file.local.path
                    }
                } catch {
                    logger.debug("*** TDLIB bridge failed to download chat avatar: \(self.makeErrorMessage(from: error), privacy: .public).")
                }

                return nil
            }

            private func makeDefaultSendOptions() -> MessageSendOptions {

                .init(
                    allowPaidBroadcast: false,
                    disableNotification: false,
                    effectId: 0,
                    fromBackground: false,
                    onlyPreview: false,
                    paidMessageStarCount: 0,
                    protectContent: false,
                    schedulingState: nil,
                    sendingId: 0,
                    suggestedPostInfo: nil,
                    updateOrderOfInstalledStickerSets: false
                )
            }

            private func makeDialogPhotoResource(
                from content: MessageContent?,
                using client: TDLibClient
            ) async throws -> DialogPhotoResource? {

                guard case .messagePhoto(let value) = content else {
                    return nil
                }

                guard let size = value.photo.sizes.max(by: {
                    ($0.width * $0.height) < ($1.width * $1.height)
                }) else {
                    return nil
                }

                if size.photo.local.path.isEmpty == false {
                    return .init(
                        localPath: size.photo.local.path,
                        width: size.width,
                        height: size.height
                    )
                }

                let file = try await client.downloadFile(
                    fileId: size.photo.id,
                    limit: 0,
                    offset: 0,
                    priority: 16,
                    synchronous: true
                )

                guard file.local.path.isEmpty == false else {
                    return nil
                }

                return .init(
                    localPath: file.local.path,
                    width: size.width,
                    height: size.height
                )
            }

            private struct DialogFetchResult {

                let item: Chats.List.Item?
                let isUnauthorized: Bool

            } // DialogFetchResult

            private struct DialogPhotoResource {

                let localPath: String
                let width: Int
                let height: Int

            } // DialogPhotoResource
#endif

        } // Impl

    } // Bridge

} // TelegramClient
