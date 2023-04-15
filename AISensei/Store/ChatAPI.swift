//
//  ChatAPI.swift
//  AISensei
//
//  Created by k2o on 2023/04/08.
//

import Foundation

final class ChatAPI {
    private let apiKey: String
    private let session: URLSession
    private let requestEncoder: JSONEncoder
    private let responseDecoder: JSONDecoder

    init(apiKey: String) {
        self.apiKey = apiKey
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        session = URLSession(configuration: configuration)
        
        requestEncoder = JSONEncoder()
        requestEncoder.keyEncodingStrategy = .convertToSnakeCase
        
        responseDecoder = JSONDecoder()
        responseDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    private struct RequestBody: Encodable {
        let model: String
        let messages: [ChatMessageResponse]
        let stream: Bool
    }
    
    private struct ResponseBody: Decodable {
        let id: String
        let object: String
        let created: Int
        let model: String
        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int
        }
        let usage: Usage
        struct Choice: Decodable {
            let message: ChatMessageResponse
            let finishReason: String
            let index: Int
        }
        let choices: [Choice]
    }

    private struct StreamResponseBody: Decodable {
        struct Choice: Decodable {
            let finishReason: String?
            struct Delta: Decodable {
                let role: String?
                let content: String?
            }
            let delta: Delta
        }
        let choices: [Choice]
    }

    func send(
        _ prompt: String,
        history messages: [ChatMessage]
    ) async throws -> ChatMessageResponse {
        let (data, response) = try await session.data(for: .post(
            "https://api.openai.com/v1/chat/completions",
            body: RequestBody(
                model: "gpt-3.5-turbo",
                messages: messages.map(ChatMessageResponse.init) + [.init(role: "user", content: prompt)],
                stream: false
            ),
            requestEncoder: requestEncoder
        ))
        guard
            let httpResponse = response as? HTTPURLResponse,
            200...299 ~= httpResponse.statusCode
        else {
            fatalError("FIXME")
        }

        let responseBody = try responseDecoder.decode(ResponseBody.self, from: data)
        guard let message = responseBody.choices.last?.message else {
            fatalError("FIXME")
        }
        
        return message
    }
    
    func sendStream(
        _ prompt: String,
        history messages: [ChatMessage]
    ) async throws -> AsyncThrowingStream<ChatMessageResponse, Error> {
        let (result, response) = try await session.bytes(for: .post(
            "https://api.openai.com/v1/chat/completions",
            body: RequestBody(
                model: "gpt-3.5-turbo",
                messages: messages.map(ChatMessageResponse.init) + [.init(role: "user", content: prompt)],
                stream: true
            ),
            requestEncoder: requestEncoder
        ))
        guard
            let httpResponse = response as? HTTPURLResponse,
            200...299 ~= httpResponse.statusCode
        else {
            fatalError("FIXME")
        }
         
        return .init { continuation in
            Task {
                do {
                    var responseRole = ""
                    var responseText = ""
                    for try await line in result.lines {
                        guard
                            line.hasPrefix("data: "),
                            let data = line.dropFirst(6).data(using: .utf8),
                            let response = try? responseDecoder.decode(StreamResponseBody.self, from: data),
                            let choice = response.choices.first
                        else {
                            continue
                        }
                        
                        if
                            responseRole.isEmpty,
                            let role = choice.delta.role
                        {
                            responseRole = role
                        }
                        if let text = choice.delta.content {
                            responseText += text
                        }
                        
                        continuation.yield(.init(role: responseRole, content: responseText))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

private extension ChatMessageResponse {
    init(_ message: ChatMessage) {
        self.role = message.role
        self.content = message.content
    }
}
