//
//  Controls+Button+ViewModel.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import Combine

extension Controls.Button {

    @MainActor
    final class ViewModel: ObservableObject {

        enum Style {

            case primary
            case secondary
            case plainWarning

        } // Style

        @Published var title: String
        @Published var style: Style
        @Published var isDisabled: Bool

        var action: (() -> Void)?

        init(
            title: String,
            style: Style,
            isDisabled: Bool = false,
            action: (() -> Void)? = nil
        ) {

            self.title = title
            self.style = style
            self.isDisabled = isDisabled
            self.action = action
        }

    } // ViewModel

} // Controls.Button
