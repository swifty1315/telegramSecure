//
//  Tabbar.swift
//  SecureTelegram
//
//  Created by OpenAI on 12.05.2026.
//

import SwiftUI
import Combine

struct Tabbar {

    struct Coordinator {

        enum TabbarVisibilitySource: Equatable {

            case homeDetails
            case favourite
            case myAnnouncement
            case chat
            case tabbar
            case other

        } // TabbarVisibilitySource

        @MainActor
        final class Impl: ObservableObject {

            @Published var source: TabbarVisibilitySource?
            @Published var isTabbarVisible = true

            func setVisibility(
                source: TabbarVisibilitySource,
                isVisible: Bool
            ) {

                self.source = source
                self.isTabbarVisible = isVisible
            }

            func clear(source: TabbarVisibilitySource) {

                guard self.source == source else {
                    return
                }

                self.source = .tabbar
                self.isTabbarVisible = true
            }

        } // Impl

    } // Coordinator

} // Tabbar

private struct TabbarVisibilityModifier: ViewModifier {

    @EnvironmentObject private var coordinator: Tabbar.Coordinator.Impl

    let source: Tabbar.Coordinator.TabbarVisibilitySource
    let isVisible: Bool

    func body(content: Content) -> some View {

        content
            .toolbar(isVisible ? .visible : .hidden, for: .tabBar)
            .onAppear {
                coordinator.setVisibility(
                    source: source,
                    isVisible: isVisible
                )
            }
            .onDisappear {
                if isVisible == false {
                    coordinator.clear(source: source)
                }
            }
    }

}

extension View {

    func tabbarVisibility(
        source: Tabbar.Coordinator.TabbarVisibilitySource,
        isVisible: Bool
    ) -> some View {

        modifier(
            TabbarVisibilityModifier(
                source: source,
                isVisible: isVisible
            )
        )
    }

}
