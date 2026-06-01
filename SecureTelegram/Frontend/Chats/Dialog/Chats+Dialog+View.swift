//
//  Chats+Dialog+View.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI
import Combine

extension Chats.Dialog {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Chats.Dialog.ViewModel.Impl
        @State private var preview: ImagePreview?
        @Namespace private var previewNamespace

        var body: some SwiftUI.View {

            ZStack {
                Group {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage, viewModel.messages.isEmpty {
                        errorView(message: errorMessage)
                    } else if viewModel.messages.isEmpty {
                        emptyView
                    } else {
                        messagesView
                    }
                }

                if let preview {
                    ImagePreviewOverlay(
                        preview: preview,
                        namespace: previewNamespace
                    ) {
                        closePreview()
                    }
                    .zIndex(10)
                }
            }
            .task {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .background(Color(.systemBackground))
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(preview == nil ? .visible : .hidden, for: .navigationBar)
            .tabbarVisibility(source: .chat, isVisible: false)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if preview == nil {
                    Chats.Dialog.Composer.View(viewModel: viewModel.composerViewModel)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        avatar

                        Text(viewModel.navigationTitle)

                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.text)
                    }
                }
            }
            .onReceive(viewModel.composerViewModel.$action.compactMap { $0 }) { action in
                switch action {
                case .didSend:
                    viewModel.refresh()
                case .showError:
                    break
                }

                viewModel.composerViewModel.consumeAction()
            }
        }

        private var loadingView: some SwiftUI.View {

            ProgressView()

                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var emptyView: some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.emptyTitle)

                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(viewModel.emptyMessage)

                    .font(.body)
                    .foregroundStyle(Color.secondaryText)
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }

        private func errorView(message: String) -> some SwiftUI.View {

            VStack(alignment: .leading, spacing: 12) {
                Text("Failed to load messages")

                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.text)

                Text(message)

                    .font(.body)
                    .foregroundStyle(Color.secondaryText)
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }

        private var messagesView: some SwiftUI.View {

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(
                        alignment: .leading,
                        spacing: 10,
                        pinnedViews: [.sectionHeaders]
                    ) {
                        ForEach(viewModel.messageSections) { section in
                            Section {
                                ForEach(section.messages) { message in
                                    messageRow(message)
                                        .id(message.id)
                                }
                            } header: {
                                sectionHeader(for: section.day)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    viewModel.refresh()
                }
                .onAppear {
                    scrollToLastMessage(using: proxy, animated: false)
                }

            }
        }

        private func sectionHeader(for day: Date) -> some SwiftUI.View {

            HStack {
                Spacer()

                Text(formattedDay(for: day))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .glassHeaderBackground()

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }

        private func messageRow(_ message: Chats.Dialog.Message) -> some SwiftUI.View {

            HStack {
                if message.isOutgoing {
                    Spacer(minLength: 48)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if let imageLocalPath = message.imageLocalPath {
                        messageImage(
                            localPath: imageLocalPath,
                            aspectRatio: imageAspectRatio(for: message),
                            namespace: previewNamespace
                        )
                        .onTapGesture {
                            openPreview(
                                localPath: imageLocalPath,
                                aspectRatio: imageAspectRatio(for: message)
                            )
                        }
                    }

                    if message.text.isEmpty == false || message.imageLocalPath == nil {
                        Text(message.text.isEmpty ? "Unsupported message" : message.text)

                            .font(.system(size: 16))
                            .foregroundStyle(message.isOutgoing ? Color.white : Color.text)
                    }

                    Text(formattedTime(for: message.sentAt))

                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(message.isOutgoing ? Color.white.opacity(0.8) : Color.secondaryText)
                }

                .padding(.horizontal, message.imageLocalPath == nil ? 14 : 8)
                .padding(.vertical, message.imageLocalPath == nil ? 10 : 8)
                .background(bubbleBackground(for: message), in: RoundedRectangle(cornerRadius: 18))

                if message.isOutgoing == false {
                    Spacer(minLength: 48)
                }
            }
        }

        private func messageImage(
            localPath: String,
            aspectRatio: CGFloat,
            namespace: Namespace.ID
        ) -> some SwiftUI.View {

            SwiftUI.AsyncImage(url: URL(fileURLWithPath: localPath)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.08))

                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.08))

                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.secondaryText)
                    }
                @unknown default:
                    Color.clear
                }
            }
            .frame(maxWidth: 240)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.06))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .matchedGeometryEffect(
                id: localPath,
                in: namespace,
                isSource: preview?.localPath != localPath
            )
            .opacity(preview?.localPath == localPath ? 0 : 1)
        }

        private var avatar: some SwiftUI.View {

            ZStack {
                Circle()

                    .fill(
                        LinearGradient(
                            colors: [
                                Color.registrationGradient1,
                                Color.registrationGradient2,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(initials(for: viewModel.navigationTitle))

                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Controls.AsyncImage.View(
                    viewModel: .init(localPath: viewModel.avatarLocalPath)
                )

                .clipShape(Circle())
            }

            .frame(width: 28, height: 28)
        }

        private func bubbleBackground(for message: Chats.Dialog.Message) -> some ShapeStyle {

            if message.isOutgoing {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color.registrationGradient1,
                            Color.registrationGradient2,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }

            return AnyShapeStyle(Color(.secondarySystemBackground))
        }

        private func formattedTime(for timestamp: Int) -> String {

            guard timestamp > 0 else {
                return ""
            }

            return Self.timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
        }

        private func formattedDay(for day: Date) -> String {

            if Calendar.current.isDateInToday(day) {
                return "Today"
            }

            if Calendar.current.isDateInYesterday(day) {
                return "Yesterday"
            }

            return Self.dayFormatter.string(from: day)
        }

        private func imageAspectRatio(for message: Chats.Dialog.Message) -> CGFloat {

            guard let imageWidth = message.imageWidth,
                  let imageHeight = message.imageHeight,
                  imageWidth > 0,
                  imageHeight > 0 else {
                return 1
            }

            return CGFloat(imageWidth) / CGFloat(imageHeight)
        }

        private func openPreview(
            localPath: String,
            aspectRatio: CGFloat
        ) {

            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                preview = .init(
                    localPath: localPath,
                    title: viewModel.navigationTitle,
                    aspectRatio: aspectRatio
                )
            }
        }

        private func closePreview() {

            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                preview = nil
            }
        }

        private func scrollToLastMessage(
            using proxy: ScrollViewProxy,
            animated: Bool
        ) {

            guard let lastMessageID = viewModel.messages.last?.id else {
                return
            }

            let scroll = {
                proxy.scrollTo(lastMessageID, anchor: .bottom)
            }

            if animated {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    scroll()
                }
            } else {
                scroll()
            }
        }

        private func initials(for title: String) -> String {

            let components = title
                .split(separator: " ")
                .prefix(2)
                .compactMap { $0.first }

            let initials = String(components)

            if initials.isEmpty {
                return "TG"
            }

            return initials.uppercased()
        }

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter
        }()

        private static let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()

    } // View

} // Chats.Dialog

private extension Chats.Dialog.View {

    struct ImagePreview: Identifiable, Equatable {

        let localPath: String
        let title: String
        let aspectRatio: CGFloat

        var id: String {

            localPath
        }

    } // ImagePreview

    struct ImagePreviewOverlay: SwiftUI.View {

        let preview: ImagePreview
        let namespace: Namespace.ID
        let onClose: () -> Void

        @State private var scale: CGFloat = 1
        @State private var lastScale: CGFloat = 1
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        @State private var dismissOffsetY: CGFloat = 0

        var body: some SwiftUI.View {

            ZStack {
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onClose()
                    }

                image
                    .offset(x: offset.width, y: offset.height + dismissOffsetY)
                    .scaleEffect(scale)
                    .gesture(combinedGesture)
                    .animation(.spring(response: 0.24, dampingFraction: 0.86), value: scale)
                    .animation(.spring(response: 0.24, dampingFraction: 0.86), value: offset)
                    .animation(.spring(response: 0.24, dampingFraction: 0.86), value: dismissOffsetY)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(20)
                }
            }
            .statusBarHidden()
        }

        private var image: some SwiftUI.View {

            Group {
                SwiftUI.AsyncImage(url: URL(fileURLWithPath: preview.localPath)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        VStack(spacing: 10) {
                            Image(systemName: "photo")
                                .font(.system(size: 32, weight: .medium))
                            Text("Failed to load image")
                                .font(.body)
                        }
                        .foregroundStyle(.white.opacity(0.85))
                    @unknown default:
                        Color.clear
                    }
                }
            }
            .padding(.horizontal, 12)
            .aspectRatio(preview.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .matchedGeometryEffect(
                id: preview.localPath,
                in: namespace
            )
        }

        private var combinedGesture: some Gesture {

            SimultaneousGesture(dragGesture, magnificationGesture)
        }

        private var magnificationGesture: some Gesture {

            MagnifyGesture()
                .onChanged { value in
                    scale = max(1, lastScale * value.magnification)
                }
                .onEnded { _ in
                    scale = max(1, min(scale, 4))
                    lastScale = scale

                    if scale == 1 {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
        }

        private var dragGesture: some Gesture {

            DragGesture()
                .onChanged { value in
                    if scale > 1.01 {
                        offset = .init(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                        return
                    }

                    dismissOffsetY = max(0, value.translation.height)
                }
                .onEnded { value in
                    if scale > 1.01 {
                        lastOffset = offset
                        return
                    }

                    if value.translation.height > 140 || value.predictedEndTranslation.height > 220 {
                        onClose()
                    } else {
                        dismissOffsetY = 0
                    }
                }
        }

        private var backgroundOpacity: Double {

            let progress = min(max(dismissOffsetY / 220, 0), 1)
            return 1 - (progress * 0.45)
        }

    } // ImagePreviewOverlay

}

private extension SwiftUI.View {

    @ViewBuilder
    func glassHeaderBackground() -> some SwiftUI.View {

        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: 14))
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }

}
