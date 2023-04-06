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
    enum State {
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

    init() {
        bind()
    }
    
    func prepare() async {
//        guard state == .unprepared else { return }

        isSetupRequired = apiKey.isEmpty
        state = .ready

        
        speechVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "ja-JP" }
    }
    
    func send() async {
        guard canSubmit else { return }
        
        messages.append(.init(role: "user", content: prompt))

        defer { state = .ready }
        do {
            state = .querying
            let message = try await chatService.send(prompt)
            
            prompt = ""
            messages.append(.init(message))
        } catch {
            dump(error)
        }
    }
    
    func sendStream() async {
        guard canSubmit else { return }

        messages.append(.init(role: "user", content: prompt))

        defer { state = .ready }
        do {
            state = .querying
            let stream = try await chatService.sendStream(prompt)
            
            prompt = ""
            state = .answering
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
    
    // MARK: - private
    
    @AppStorage("chatGPTAPIKey") private var apiKey = ""
    private lazy var chatService = AIChatService(apiKey: apiKey)
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
