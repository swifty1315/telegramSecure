//
//  Controls+AsyncImage+ViewModel.swift
//  SecureTelegram
//
//  Created by Codex on 12.05.2026.
//

import Foundation
import Combine

extension Controls.AsyncImage {

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var localPath: String?

        init(localPath: String?) {

            self.localPath = localPath
        }

        var url: URL? {

            guard let localPath, localPath.isEmpty == false else {
                return nil
            }

            return URL(fileURLWithPath: localPath)
        }

    } // ViewModel

} // Controls.AsyncImage
