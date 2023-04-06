//
//  AISenseiApp.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import SwiftUI

@main
struct AISenseiApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
#if os(macOS)
        Settings {
            SettingsView()
        }
#endif
    }
}
