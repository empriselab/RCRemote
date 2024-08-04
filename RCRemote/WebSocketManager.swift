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

    // 连接 WebSocket
    func connect(completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "ws://\(address):\(port)") else {
            completion(false, "Invalid URL. Please check the address and port.")
            return
        }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        // 发送连接测试消息
        sendMessage(message: "Test Connection")

        // 接收服务器响应
        receiveMessage { response in
            completion(response == "Connection Established", "Connected to the wrong device.")
        }
    }

    // 断开连接
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        print("WebSocket disconnected")
    }
    
    // 发送坐标数据
    func sendSensorData(orie: (x: Double, y: Double, z: Double), pitch: Double, roll: Double, gripper: Double) {
        let message = "Data: \(orie.x), \(orie.y), \(orie.z), Pitch: \(pitch), Roll: \(roll), Gripper: \(gripper)"
        sendMessage(message: message)
    }
    
    // 发送简单消息
    func sendMessage(message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        if webSocketTask?.state == .running {
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                } else {
                    print("Message sent")
                }
            }
        } else {
            print("WebSocket is not in a running state")
        }
    }
    
    // 接收服务器回复
    private func receiveMessage(completion: @escaping (String) -> Void) {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                if case .string(let text) = message {
                    print(text)
                    completion(text)
                }
                // 重新调用自身以继续接收更多消息
                self.receiveMessage(completion: completion)
            }
        }
    }
    
//    func isConnected() -> Bool {
//        return webSocketTask?.state == .running
//    }
}
