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

    func allSessions() async throws -> [ChatSession] {
        return try await store
            .allSessions()
            .map(ChatSession.init)
    }
    
    func newSession() async throws -> ChatSession {
        let record = try await store.createSession(.init(title: ""))
        return .init(record: record)
    }

    func updateTitle(_ title: String, for session: ChatSession) async throws {
        guard var record = try await store.session(for: session.id) else {
            return
        }

        record.title = title
        try await store.updateSession(record)
    }

    func removeSession(_ session: ChatSession) async throws {
        try await store.deleteSession(id: session.id)
    }
    
    func messages(for session: ChatSession) async throws -> [ChatMessage] {
        return try await store
            .messages(for: session.id)
            .map(ChatMessage.init)
    }
    
    enum StreamProgress {
        case querying(ChatMessage)
        case answering(ChatMessage)
        case finalAnswer(ChatMessage)
    }
    
    func sendStream(
        _ prompt: String,
        for session: ChatSession
    ) async throws -> AsyncThrowingStream<StreamProgress, Error> {
        return .init { continuation in
            Task {
                do {
                    let messages = try await messages(for: session)
                    
                    let queryRecord = try await store.insertMessage(.init(
                        role: "user",
                        content: prompt,
                        sessionID: session.id
                    ))
                    continuation.yield(.querying(.init(record: queryRecord)))

                    let stream = try await api.sendStream(prompt, history: messages)

                    var finalMessage: ChatMessage?
                    for try await response in stream {
                        let message = ChatMessage(response: response)
                        continuation.yield(.answering(message))
                        finalMessage = message
                    }

                    if let finalMessage {
                        _ = try await store.insertMessage(.init(
                            role: finalMessage.role,
                            content: finalMessage.content,
                            sessionID: session.id
                        ))
                        continuation.yield(.finalAnswer(finalMessage))
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
