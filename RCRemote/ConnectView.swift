//
//  ConnectView.swift
//  RCRemote
//
//  Created by Qiandao Liu on 8/3/24.
//

import Foundation
import SwiftUI

struct ConnectView: View {
    @State private var address = ""
    @State private var port = ""
    @State private var connectionStatus = ""
    @State private var isConnected = false  // 控制视图切换
    @EnvironmentObject var webSocketManager: WebSocketManager

    var body: some View {
        NavigationView {
            Form {
                TextField("Server Address", text: $address)
                    .textContentType(.URL)
                    .keyboardType(.decimalPad)
                TextField("Port", text: $port)
                    .keyboardType(.numberPad)
                Button("Connect") {
                    guard !address.isEmpty, !port.isEmpty else {
                        connectionStatus = "Please fill in all fields."
                        return
                    }
                    connectToServer()
                }
                Button("Skip Pairing") {
                    isConnected = true  // Goto ContentView
                }
                Text(connectionStatus)
                    .foregroundColor(.red)
            }
            .navigationBarTitle("Connect to Server", displayMode: .inline)
        }
        .fullScreenCover(isPresented: $isConnected) {
            ContentView()
        }
    }

    private func connectToServer() {
        webSocketManager.address = address
        webSocketManager.port = port
        webSocketManager.connect { success, errorMessage in
            if success {
                connectionStatus = "Connected successfully!"
                isConnected = true  // Goto ContentView
            } else {
                connectionStatus = errorMessage
            }
        }
    }
}


#Preview {
    ConnectView()
}
