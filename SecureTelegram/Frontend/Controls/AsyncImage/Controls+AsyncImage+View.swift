//
//  Controls+AsyncImage+View.swift
//  SecureTelegram
//
//  Created by Codex on 12.05.2026.
//

import SwiftUI

extension Controls.AsyncImage {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Controls.AsyncImage.ViewModel

        var body: some SwiftUI.View {

            Group {
                if let url = viewModel.url {
                    SwiftUI.AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image

                                .resizable()
                                .scaledToFill()

                        default:
                            Color.clear
                        }
                    }
                } else {
                    Color.clear
                }
            }
        }

    } // View

} // Controls.AsyncImage
