//
//  ChatPresenter.swift
//  AISensei
//
//  Created by k2o on 2023/04/07.
//

import SwiftUI
import Combine
import AVFoundation

@MainActor
final class ChatPresenter: ObservableObject {
    let chatSession: ChatSession
    
    enum State: String {
        case unprepared
        case ready
        case querying
        case answering
    }
    @Published private(set) var state: State = .unprepared
    @Published private(set) var canEdit = false
    @Published private(set) var canSubmit = false

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

    init(chatSession: ChatSession) {
        self.chatSession = chatSession
        bind()
    }
    
    func prepare() async {
//        guard state == .unprepared else { return }

        do {
            speechVoices = AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language == "ja-JP" }

            messages = chatSession.messages.map(Message.init)
            
            isSetupRequired = apiKey.isEmpty
            state = .ready
        } catch {
            dump(error)
        }
    }
    
//    func send() async {
//        guard
//            canSubmit,
//            let chatSession
//        else { return }
//
//        messages.append(.init(role: "user", content: prompt))
//
//        defer { state = .ready }
//        do {
//            state = .querying
//            let message = try await chatService.send(prompt)
//
//            prompt = ""
//            messages.append(.init(message))
//        } catch {
//            dump(error)
//        }
//    }
    
    func sendStream() async {
        guard canSubmit else { return }

        defer { state = .ready }
        do {
            state = .querying
            let stream = try await chatService.sendStream(prompt, for: chatSession)

            let lastMessages = chatSession.messages.map(Message.init)
            // promptを追加したメッセージを反映
            messages = lastMessages
            
            // 回答中のメッセージを反映
            prompt = ""
            state = .answering
            for try await message in stream {
                let answeringMessage = Message(message)
                messages = lastMessages + [answeringMessage]
            }
            
            // 回答後の最終メッセージを反映
            messages = chatSession.messages.map(Message.init)
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
    
    // MARK: - private
    
    @AppStorage("chatGPTAPIKey") private var apiKey = ""
    private lazy var chatService = ChatService(
        api: ChatAPI(apiKey: apiKey),
        store: ChatStore.shared
    )
    
    private let speechSynthsizer = AVSpeechSynthesizer()
    private var speechVoices: [AVSpeechSynthesisVoice] = []
    private var cancellables = Set<AnyCancellable>()
    
    private func bind() {
        // canEdit <= state
        $state
            .map {
                switch $0 {
                case .ready:
                    return true
                case .unprepared, .querying, .answering:
                    return false
                }
            }
            .assign(to: \.canEdit, on: self)
            .store(in: &cancellables)
        
        // canSubmit <= state, prompt
        Publishers
            .CombineLatest($state, $prompt)
            .map {
                switch $0 {
                case .ready:
                    return !$1.isEmpty
                case .unprepared, .querying, .answering:
                    return false
                }
            }
            .assign(to: \.canSubmit, on: self)
            .store(in: &cancellables)
    }
}
