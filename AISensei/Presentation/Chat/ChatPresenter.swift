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
    @Published var prompt: String = ""
//    @Published var prompt: String = "猫の遺伝子組み合わせによる毛色の違いを表にしてください"

    @Published var messages: [ChatMessage] = []

    init(chatSession: ChatSession) {
        self.chatSession = chatSession
        bind()
    }
    
    func prepare() async {
//        guard state == .unprepared else { return }

        do {
            speechVoices = AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language == "ja-JP" }

            messages = try await chatService.messages(for: chatSession)
            
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
            // タイトルが空の場合は最初の質問を反映
            if chatSession.title.isEmpty {
                try await chatService.updateTitle(prompt, for: chatSession)
            }
            
            var lastMessages: [ChatMessage] = []
            let stream = try await chatService.sendStream(prompt, for: chatSession)
            for try await progress in stream {
                switch progress {
                case .querying(let message):
                    // promptを追加したメッセージ
                    state = .querying
                    prompt = ""
                    messages.append(message)
                    lastMessages = messages
                case .answering(let message):
                    // 回答中のメッセージ
                    state = .answering
                    messages = lastMessages + [message]
                case .finalAnswer(let message):
                    // 最終的なメッセージ
                    messages = lastMessages + [message]
                }
            }
        } catch {
            dump(error)
        }
    }
    
    func copy(message: ChatMessage) async {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
    }
    
    func speak(message: ChatMessage) async {
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
