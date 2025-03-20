//
//  FilterMixerApp.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import SwiftUI
import TipKit

@main
struct FilterMixerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // try? Tips.resetDatastore()
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
