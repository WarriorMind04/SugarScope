//
//  SugarScopeWatchApp.swift
//  SugarScope Watch
//
//  Watch app for reminder confirmations and quick log. Add this target in Xcode:
//  File → New → Target → Watch App, then add these files to the Watch target.
//

import SwiftUI

@main
struct SugarScopeWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
