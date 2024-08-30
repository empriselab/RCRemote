//
//  WebSocketManager.swift
//  RCRemote
//
//  Created by Qiandao Liu on 8/3/24.
//

import Foundation

class WebSocketManager: ObservableObject {
    @Published var connectionError = false  // detect error，report error instead crush
    @Published var isConnected = false  // monitor connection
    @Published var highPrecision = false  // control data precision: 0.001 or 0.000001
    @Published var networkDelay: Int = 0
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private var lastSendTime: Date?  // record last message sending time
    
    // Properties for sensor data
    @Published var orientationChange = (x: 0.0, y: 0.0, z: 0.0)
    @Published var pitchChange = 0.0
    @Published var rollChange = 0.0
    @Published var gripperValue = 0.0
    @Published var height = 0.0  // height
    
    func updateData(orieX: Double, orieY: Double, orieZ: Double, pitch: Double, roll: Double, gripper: Double, height: Double) {
        self.orientationChange.x = orieX
        self.orientationChange.y = orieY
        self.orientationChange.z = orieZ
        self.pitchChange = pitch
        self.rollChange = roll
        self.gripperValue = gripper
        self.height = height
        print("Current sensor data - OrieX: \(self.orientationChange.x), OrieY: \(self.orientationChange.y), OrieZ: \(self.orientationChange.z), Pitch: \(self.pitchChange), Roll: \(self.rollChange), Gripper: \(self.gripperValue), Height: \(self.height)")
    }
    
    // Connect to WebSocket
    func connect(address: String, port: String) {
        guard let url = URL(string: "ws://\(address):\(port)") else {
            print("Invalid URL.")
            DispatchQueue.main.async {
                self.connectionError = true
            }
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()  // start to receive message
        sendMessage(message: "Test Connection")
    }
    
    // Send message
    func sendMessage(message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Sending Error: \(error)")
                DispatchQueue.main.async {
                    self.connectionError = true
                }
            } else {
                print("Message sent: \(message)")
            }
        }
    }
    
    // receive message
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {  // make sure it updates on the main thread
                switch result {
                case .failure(let error):
                    print("Receiving Error: \(error)")
                    self?.isConnected = false
                case .success(let message):
                    if case .string(let text) = message {
                        self?.handleReceivedMessage(text)
                        self?.receiveMessage()  // recursion, start receive next message
                    }
                }
            }
        }
    }
    
    // process the message received
    private func handleReceivedMessage(_ message: String) {
        switch message {
        case "Connection Established":
            isConnected = true
            connectionError = false
            sendSensorData()  // start send data
        case "received":
            // Server received data, calculate delay and send next one
            if let lastSendTime = lastSendTime {
                let delay = Date().timeIntervalSince(lastSendTime)
                DispatchQueue.main.async {
                    self.networkDelay = Int(delay * 1000)  // convert delay to ms
                }
            }
            sendSensorData()
        default:
            print("Received: \(message)")
        }
    }
    
    // update precision: 0.001 or 0.000001
    func updatePrecision(high: Bool) {
        highPrecision = high
    }
    
    // send sensor data
    private func sendSensorData() {
        let format = highPrecision ? "%.6f" : "%.3f"
        let dataMessage = "Data: OrieX=\(String(format: format, orientationChange.x)), OrieY=\(String(format: format, orientationChange.y)), OrieZ=\(String(format: format, orientationChange.z)), Pitch=\(String(format: format, pitchChange)), Roll=\(String(format: format, rollChange)), Gripper=\(Int(gripperValue)), Height=\(String(format: format, height))"
        lastSendTime = Date()  // update sending time
        sendMessage(message: dataMessage)
    }
    
    // disconnection
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        connectionError = false
        print("WebSocket disconnected")
    }
}
