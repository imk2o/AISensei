//
//  ChatView.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import SwiftUI
import MarkdownUI
import Introspect

struct ChatView: View {
    @ObservedObject private(set) var presenter: ChatPresenter

    init(session: ChatSession) {
        self.presenter = .init(chatSession: session)
    }

    private enum Field: Hashable {
        case prompt
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        Group {
            if presenter.state == .unprepared {
                ProgressView()
            } else if presenter.isSetupRequired {
                Button("Open Settings...") { showSettings() }
            } else {
                contentView()
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .task {
            await presenter.prepare()
            // プロンプトにフォーカス
            focusedField = .prompt
        }
    }
    
    private func contentView() -> some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(presenter.messages) { message in
                        HStack(alignment: .bottom) {
                            Markdown(message.content)
                                .id(message)
                            VStack {
                                Button(
                                    action: { Task { await presenter.speak(message: message) } },
                                    label: { Image(systemName: "speaker.wave.2") }
                                )
                                Button(
                                    action: { Task { await presenter.copy(message: message) } },
                                    label: { Image(systemName: "doc.on.doc") }
                                )
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    Spacer(minLength: 400)
                }
                .onChange(of: presenter.anchorMessage) { message in
                    if let message {
                        withAnimation {
                            proxy.scrollTo(message, anchor: .top)
                        }
                    }
                }
            }
            HStack {
                TextEditor(text: $presenter.prompt)
//                    .introspectTextView { textView in
//                        textView.becomeFirstResponder()
//                    }
                    .focused($focusedField, equals: .prompt)
                    .disabled(!presenter.canEdit)
                    .frame(minHeight: 40, maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                Button(
                    action: {
                        Task { await presenter.sendStream() }
                    },
                    label: {
                        if presenter.state == .querying {
                            ProgressView()
                        } else {
                            Text("Send")
                        }
                    }
                )
                .keyboardShortcut(.return)
                .disabled(!presenter.canSubmit)
            }
            .padding()
        }
        .padding()
    }
    
    private func showSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task {
                await UIApplication.shared.open(url)
            }
        }
        
//        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
//        NSApp.activate(ignoringOtherApps: true)
    }
}
