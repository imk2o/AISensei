//
//  ChatSession.swift
//  AISensei
//
//  Created by k2o on 2023/04/10.
//

import Foundation

struct ChatSession: Identifiable, Sendable {
    let id: Int64
    var title: String
}

// MARK: -

extension ChatSession {
    init(record: ChatSessionRecord) {
        self.id = record.id ?? 0
        self.title = record.title
    }
}
