//
//  ContentPresenter.swift
//  AISensei
//
//  Created by k2o on 2023/04/08.
//

import SwiftUI

@MainActor
final class ContentPresenter: ObservableObject {
    struct Item: Identifiable, Hashable {
        let id = UUID()
        let session: ChatSession

        var title: String {
            return session.title.isEmpty ? "(New Session)" : session.title
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    @Published private(set) var items: [Item] = []
    
    func prepare() async {
        do {
            try await refresh()
        } catch {
            dump(error)
        }
    }
    
    @discardableResult
    func newSession() async -> Item? {
        do {
            let session = try await chatService.newSession()
            let item = Item(session: session)
            items.append(item)
            return item
        } catch {
            dump(error)
            return nil
        }
    }
    
    func removeSession(_ session: ChatSession) async {
        do {
            try await chatService.removeSession(session)
            try await refresh()
        } catch {
            dump(error)
        }
    }
    
    private func refresh() async throws {
        items = try await chatService
            .allSessions()
            .map(Item.init)
    }
    
    @AppStorage("chatGPTAPIKey") private var apiKey = ""
    private lazy var chatService = ChatService(
        api: ChatAPI(apiKey: apiKey),
        store: ChatStore.shared
    )
}
