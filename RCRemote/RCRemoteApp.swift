//
//  RCRemoteApp.swift
//  RCRemote
//
//  Created by Qiandao Liu on 7/18/24.
//

import Foundation
import SwiftUI

@main
struct RCRemoteApp: App {
    var webSocketManager = WebSocketManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(webSocketManager)  // Import WebSocketManager
        }
    }
}
