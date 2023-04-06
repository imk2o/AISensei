//
//  ChatPresenter.swift
//  AISensei
//
//  Created by k2o on 2023/04/07.
//

import SwiftUI
import AVFoundation

@MainActor
final class ChatPresenter: ObservableObject {
    enum State {
        case unprepared
        case ready
        case querying
        case answering
    }
    @Published private(set) var state: State = .unprepared
    @Published private(set) var isSetupRequired = false
    @Published var prompt: String = "猫の遺伝子組み合わせによる毛色の違いを表にしてください"
    
    struct Message: Hashable {
        let role: String
        var content: String

        init(role: String, content: String) {
            self.role = role
            self.content = content
        }

        init(_ chatMessage: ChatMessage) {
            self.role = chatMessage.role
            self.content = chatMessage.content
        }
    }
    @Published var messages: [Message] = []

    @AppStorage("chatGPTAPIKey") private var apiKey = ""
    
    private let speechSynthsizer = AVSpeechSynthesizer()
    private var speechVoices: [AVSpeechSynthesisVoice] = []

    func prepare() async {
//        guard state == .unprepared else { return }

        isSetupRequired = apiKey.isEmpty
        state = .ready

        
        speechVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "ja-JP" }
    }
    
    func send() async {
        messages.append(.init(role: "user", content: prompt))

        let service = AIChatService(apiKey: apiKey)
        do {
            let message = try await service.send(prompt)
            messages.append(.init(message))
        } catch {
            dump(error)
        }
    }
    
    func sendStream() async {
        messages.append(.init(role: "user", content: prompt))

        let service = AIChatService(apiKey: apiKey)
        do {
            let stream = try await service.sendStream(prompt)
            
            messages.append(.init(role: "", content: ""))
            var joinedText = ""
            for try await text in stream {
                joinedText += text
                messages[messages.count - 1].content = joinedText
            }
        } catch {
            dump(error)
        }
    }
    
    func copy(message: Message) async {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
    }
    
    func speak(message: Message) async {
        speechSynthsizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message.content)
        utterance.voice = speechVoices.randomElement()
        speechSynthsizer.speak(utterance)
    }
}
