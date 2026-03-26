//
//  ObiApp.swift
//  Obi
//
//  Created by 長田晃輔 on 2026/03/13.
//

import SwiftUI

@main
struct ObiApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    print("📱 [ObiApp] Received URL: \(url.absoluteString)")
                    deepLinkManager.handleURL(url)
                }
        }
    }
}
