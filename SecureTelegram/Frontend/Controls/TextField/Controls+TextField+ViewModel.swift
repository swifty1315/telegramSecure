//
//  Controls+TextField+ViewModel.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import SwiftUI
import Combine

extension Controls.TextField {

    @MainActor
    final class ViewModel: ObservableObject {

        enum Kind {

            case regular
            case secure

        } // Kind

        @Published var placeholder: String
        @Published var text: String
        @Published var kind: Kind
        @Published var keyboardType: UIKeyboardType
        @Published var textContentType: UITextContentType?

        init(
            placeholder: String,
            text: String = "",
            kind: Kind = .regular,
            keyboardType: UIKeyboardType = .default,
            textContentType: UITextContentType? = nil
        ) {

            self.placeholder = placeholder
            self.text = text
            self.kind = kind
            self.keyboardType = keyboardType
            self.textContentType = textContentType
        }

    } // ViewModel

} // Controls.TextField
