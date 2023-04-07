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
    @StateObject var presenter = ChatPresenter()
    private enum Field: Hashable {
        case prompt
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        Group {
            if presenter.state == .unprepared {
                ProgressView()
            } else if presenter.isSetupRequired {
                Button("Setup...") { showSettings() }
                    .buttonStyle(.link)
            } else {
                contentView()
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .onAppear {
            Task { await presenter.prepare() }
            // プロンプトにフォーカス
            focusedField = .prompt
        }
    }
    
    private func contentView() -> some View {
        VStack {
            List {
                ForEach(presenter.messages, id: \.self) { message in
                    Section {
                        HStack(alignment: .bottom) {
                            Markdown(message.content)
                            VStack {
                                Button(
                                    action: { Task { await presenter.speak(message: message) } },
                                    label: { Image(systemName: "speaker.wave.2") }
                                )
                                .buttonStyle(.link)
                                Button(
                                    action: { Task { await presenter.copy(message: message) } },
                                    label: { Image(systemName: "doc.on.doc") }
                                )
                                .buttonStyle(.link)
                            }
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
                Button("Send", action: { Task { await presenter.sendStream() } })
                    .keyboardShortcut(.return)
                    .disabled(!presenter.canSubmit)
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

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}