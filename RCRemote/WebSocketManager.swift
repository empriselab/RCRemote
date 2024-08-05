//
//  WebSocketManager.swift
//  RCRemote
//
//  Created by Qiandao Liu on 8/3/24.
//

import Foundation

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    var address: String = ""
    var port: String = ""
    
    private var sendDataQueue: [(x: Double, y: Double, z: Double, pitch: Double, roll: Double, gripper: Double)] = []
    private let queueLock = DispatchQueue(label: "com.websocketManager.queueLock")

    // Connect to WebSocket
    func connect(completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "ws://\(address):\(port)") else {
            completion(false, "Invalid. Please check the address and port.")
            return
        }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        sendMessage(message: "Test Connection")
        
        sendMessage(message: "Data: goodgood study")

        receiveMessage { [weak self] response in
            if response == "Connection Established" {
                completion(true, "Connected successfully.")
                self?.startSendingData()
            } else {
                completion(false, "Connected to the wrong device.")
            }
        }
    }
    
    
    func startSendingData() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while true {
                if self?.isConnected() == true {
                    self?.queueLock.sync {
                        if !self!.sendDataQueue.isEmpty {
                            let data = self!.sendDataQueue.removeFirst()
                            let message = "Data: \(data.x), \(data.y), \(data.z), Pitch: \(data.pitch), Roll: \(data.roll), Gripper: \(data.gripper)"
                            print(message)
                            self?.sendMessage(message: message)
                        }
                    }
                }
                Thread.sleep(forTimeInterval: 1.0) // Adjust this value based on your needs
            }
        }
    }

    func enqueueSensorData(orie: (x: Double, y: Double, z: Double), pitch: Double, roll: Double, gripper: Double) {
        queueLock.sync {
            sendDataQueue.append((orie.x, orie.y, orie.z, pitch, roll, gripper))
        }
    }
    
    func sendMessage(message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        print(message)
        if isConnected() {
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("Send Error: \(error)")
                } else {
                    print("Message sent")
                }
            }
        } else {
            print("isConnected == false")
        }
    }
    
    private func receiveMessage(completion: @escaping (String) -> Void) {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print("Receive Error: \(error)")
            case .success(let message):
                if case .string(let text) = message {
                    print(text)
                    completion(text)
                }
                
                if self.isConnected() {
                    print("connect when receive")
                } else {
                    print("not connect when receive")
                }
                // 重新调用自身以继续接收更多消息
                self.receiveMessage(completion: completion)
            }
        }
    }
    
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        print("WebSocket disconnected")
    }
    
    func isConnected() -> Bool {
        return webSocketTask?.state == .running
    }
}
