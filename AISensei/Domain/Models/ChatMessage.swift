//
//  ChatMessage.swift
//  AISensei
//
//  Created by k2o on 2023/04/03.
//

import Foundation

struct ChatMessage: Sendable, Identifiable, Codable, Hashable {
    let id: String
    let role: String
    let content: String
}

// MARK: -

extension ChatMessage {
    init(record: ChatMessageRecord) {
        self.id = record.id.flatMap(String.init) ?? ""
        self.role = record.role
        self.content = record.content
    }
    
    init(response: ChatMessageResponse, id: String) {
        self.id = id
        self.role = response.role
        self.content = response.content
    }
}
