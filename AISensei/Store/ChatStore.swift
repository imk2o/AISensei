//
//  ChatStore.swift
//  AISensei
//
//  Created by k2o on 2023/04/08.
//

import Foundation

protocol ChatSession: AnyObject {
    var messages: [ChatMessage] { get }
}

final class ChatStore {
    static let shared = ChatStore()		// FIXME
    
    private class DefaultChatSession: ChatSession {
        var messages: [ChatMessage]
        
        init() {
            self.messages = []
        }
    }

    private var sessions: [ChatSession] = []
    
    func allSessions() async throws -> [ChatSession] {
        return sessions
    }
    
    func newSession() async throws -> ChatSession {
        return DefaultChatSession()
    }
    
    func store(message: ChatMessage, for session: ChatSession) async throws {
        guard let session = session as? DefaultChatSession else {
            return
        }

        session.messages.append(message)
    }
}
