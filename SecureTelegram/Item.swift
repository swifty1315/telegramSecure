//
//  Item.swift
//  SecureTelegram
//
//  Created by Ilya on 21.04.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
