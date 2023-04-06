//
//  ContentView.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import SwiftUI
import MarkdownUI
import Introspect
import AVFoundation

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        Group {
            if viewModel.state == .unprepared {
                ProgressView()
            } else if viewModel.isSetupRequired {
                Button("Setup...") { showSettings() }
                    .buttonStyle(.link)
            } else {
                chatView()
            }
        }
        .onAppear { Task { await viewModel.prepare() } }
    }
    
    private func chatView() -> some View {
        VStack {
            List {
                ForEach(viewModel.messages, id: \.self) { message in
                    Section {
                        HStack(alignment: .bottom) {
                            Markdown(message.content)
                            VStack {
                                Button(
                                    action: { Task { await viewModel.speak(message: message) } },
                                    label: { Image(systemName: "speaker.wave.2") }
                                )
                                .buttonStyle(.link)
                                Button(
                                    action: { Task { await viewModel.copy(message: message) } },
                                    label: { Image(systemName: "doc.on.doc") }
                                )
                                .buttonStyle(.link)
                            }
                        }
                    }
                }
            }
            HStack {
                TextEditor(text: $viewModel.prompt)
//                    .introspectTextView { textView in
//                        textView.becomeFirstResponder()
//                    }
                    .frame(minHeight: 40, maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Submit", action: { Task { await viewModel.sendStream() } })
                    .keyboardShortcut(.return)
            }
            .padding()
        }
        .padding()
    }
    
    private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@MainActor
final class ViewModel: ObservableObject {
    struct Message: Codable, Hashable {
        let role: String
        var content: String
    }
    struct Parameter: Encodable {
        let model: String
        let messages: [Message]
    }
    struct Response: Decodable {
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
            let message: Message
            let finishReason: String
            let index: Int
        }
        let choices: [Choice]
    }

    enum State {
        case unprepared
        case ready
        case querying
        case answering
    }
    @Published private(set) var state: State = .unprepared
    @Published private(set) var isSetupRequired = false
    @Published var prompt: String = "猫の遺伝子組み合わせによる毛色の違いを表にしてください"
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
    
    func sendStream() async {
        messages.append(.init(role: "user", content: prompt))

        let service = ChatAIService(apiKey: apiKey)
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
    
    func send() async {
        messages.append(.init(role: "user", content: prompt))
        
        let parameter = Parameter(
            model: "gpt-3.5-turbo",
            messages: messages
        )
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try? jsonEncoder.encode(parameter)
        
        do {
            let (data, response) = try await session.data(for: request)

            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            {
                let responseData = try jsonDecoder.decode(Response.self, from: data)
                dump(responseData)
                if let choice = responseData.choices.last {
                    messages.append(choice.message)
                }
            }
        } catch {
            dump(error)
        }
    }
}
