//
//  ChatAIService.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import Foundation

final class ChatAIService {
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
    
    func sendStream(_ message: String) async throws -> AsyncThrowingStream<String, Error> {
        struct Body: Encodable {
            let model: String
            let messages: [ChatMessage]
            let stream: Bool
        }
        struct Response: Decodable {
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


        let (result, response) = try await session.bytes(for: .post(
            "https://api.openai.com/v1/chat/completions",
            body: Body(
                model: "gpt-3.5-turbo",
                messages: [.init(role: "user", content: message)],
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
                           let response = try? responseDecoder.decode(Response.self, from: data),
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
