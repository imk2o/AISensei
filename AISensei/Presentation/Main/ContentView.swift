//
//  ContentView.swift
//  AISensei
//
//  Created by k2o on 2023/04/08.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var presenter = ContentPresenter()
    
    @State var selectedItem: ContentPresenter.Item?

    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(presenter.items, selection: $selectedItem) { item in
                    NavigationLink(item.title, value: item)
                        .contextMenu {
                            Button("Remove") {
                                Task { await presenter.removeSession(item.session) }
                            }
                        }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(240)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(
                            action: {
                                Task {
                                    if let item = await presenter.newSession() {
                                        selectedItem = item
                                    }
                                }
                            },
                            label: {
                                Image(systemName: "plus")
                            }
                        )
                        .keyboardShortcut("n")
                    }
                }
            },
            detail: {
                if let selectedItem {
                    ChatView(session: selectedItem.session)
                        // 都度新しいビューとして区別されるようIDを付与
                        // https://stackoverflow.com/questions/73267638/how-to-run-task-or-onappear-on-navigationsplitview-detail-for-every-selectio
                        .id(selectedItem.id)
                } else {
                    Text("Select")
                }
            }
        )
        .navigationSplitViewStyle(.balanced)
        .task { await presenter.prepare() }
    }
}
