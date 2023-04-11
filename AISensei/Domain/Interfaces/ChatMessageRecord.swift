//
//  ChatMessageRecord.swift
//  AISensei
//
//  Created by k2o on 2023/04/09.
//

import Foundation

struct ChatMessageRecord: Identifiable, Codable, Sendable {
    var id: Int64?
    var role: String
    var content: String
    let sessionID: Int64
    
    init(
        id: Int64? = nil,
        role: String,
        content: String,
        sessionID: Int64
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.sessionID = sessionID
    }

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case sessionID = "session_id"
    }
}
