//
//  ChatMessage.swift
//  AISensei
//
//  Created by k2o on 2023/04/03.
//

import Foundation

struct ChatMessage: Sendable, Codable, Hashable {
    let role: String
    let content: String
}
