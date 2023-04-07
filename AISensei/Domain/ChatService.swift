//
//  ChatService.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import Foundation

final class ChatService {
    init(api: ChatAPI, store: ChatStore) {
        self.api = api
        self.store = store
    }

    func newSession() async throws -> ChatSession {
        return try await store.newSession()
    }

    func sendStream(
        _ prompt: String,
        for session: ChatSession
    ) async throws -> AsyncThrowingStream<ChatMessage, Error> {
        try await store.store(message: .init(role: "user", content: prompt), for: session)
        
        let stream = try await api.sendStream(prompt)
        
        return .init { continuation in
            Task {
                do {
                    var finalMessage: ChatMessage?
                    for try await message in stream {
                        continuation.yield(message)
                        finalMessage = message
                    }

                    if let finalMessage {
                        try await store.store(message: finalMessage, for: session)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private let api: ChatAPI
    private let store: ChatStore
}
