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
            ContentView()
        }
//        MenuBarExtra("AI Sensei", systemImage: "star.fill") {
//            MenuView()
//        }
//        .menuBarExtraStyle(.window)
#if os(macOS)
        Settings {
            SettingsView()
        }
#endif
    }
}
