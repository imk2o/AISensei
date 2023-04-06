//
//  SettingsView.swift
//  AISensei
//
//  Created by k2o on 2023/04/04.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            APISettingsView()
                .tabItem { Label("API", systemImage: "gearshape.2") }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private struct GeneralSettingsView: View {
        var body: some View {
            Form {
                Text("Under construction")
            }
            .padding()
        }
    }
    
    private struct APISettingsView: View {
        @AppStorage("chatGPTAPIKey") private var apiKey = ""
        
        var body: some View {
            Form {
                Section("ChatGPT") {
                    TextField("API Key", text: $apiKey)
                }
            }
            .padding()
        }
    }
}
