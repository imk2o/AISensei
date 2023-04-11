//
//  ChatMessageResponse.swift
//  AISensei
//
//  Created by k2o on 2023/04/10.
//

import Foundation

struct ChatMessageResponse: Codable, Sendable {
    let role: String
    let content: String
}
