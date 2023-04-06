//
//  AIChatService.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import Foundation

final class AIChatService {
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
        let messages: [ChatMessage]
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
            let message: ChatMessage
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

    func send(_ prompt: String) async throws -> ChatMessage {
        let (data, response) = try await session.data(for: .post(
            "https://api.openai.com/v1/chat/completions",
            body: RequestBody(
                model: "gpt-3.5-turbo",
                messages: [.init(role: "user", content: prompt)],
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
    
    func sendStream(_ prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let (result, response) = try await session.bytes(for: .post(
            "https://api.openai.com/v1/chat/completions",
            body: RequestBody(
                model: "gpt-3.5-turbo",
                messages: [.init(role: "user", content: prompt)],
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
         
        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    var responseText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? responseDecoder.decode(StreamResponseBody.self, from: data),
                           let text = response.choices.first?.delta.content {
                            responseText += text
                            continuation.yield(text)
                        }
                    }
//                    self.appendToHistoryList(userText: text, responseText: responseText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
