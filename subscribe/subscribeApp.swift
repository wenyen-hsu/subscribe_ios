//
//  subscribeApp.swift
//  subscribe
//
//  Created by Wen Hsu on 2025/2/3.
//

import SwiftUI

@main
struct subscribeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 設定預設的外觀
                    UINavigationBar.appearance().largeTitleTextAttributes = [
                        .foregroundColor: UIColor.systemBlue
                    ]
                }
        }
    }
}
