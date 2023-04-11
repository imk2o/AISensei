//
//  AISenseiApp.swift
//  AISensei
//
//  Created by k2o on 2023/04/02.
//

import SwiftUI

@main
struct AISenseiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        bootstrap()
    }
    
    private func bootstrap() {
        try? FileManager.default.createDirectory(
            at: FileManager.default.applicationSupportDirectory,
            withIntermediateDirectories: true
        )
    }
}
