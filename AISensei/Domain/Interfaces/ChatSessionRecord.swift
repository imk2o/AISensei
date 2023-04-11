//
//  ChatSessionRecord.swift
//  AISensei
//
//  Created by k2o on 2023/04/09.
//

import Foundation

struct ChatSessionRecord: Identifiable, Codable, Sendable {
    var id: Int64?
    var title: String

    init(
        id: Int64? = nil,
        title: String
    ) {
        self.id = id
        self.title = title
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
    }
}
