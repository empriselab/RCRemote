//
//  WebSocketManager.swift
//  RCRemote
//
//  Created by Qiandao Liu on 8/3/24.
//

import Foundation

class WebSocketManager: ObservableObject {
    @Published var connectionError = false  // 用于检测是否有error，报错而不至于让程序直接崩溃
    @Published var isConnected = false  // 新增: 用于监控连接状态
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    // 更新: 连接WebSocket
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
        receiveMessage()  // 开始接收消息
        sendMessage(message: "Test Connection")  // 测试连接
    }
    
    // 更新: 发送消息
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
    
    // 更新: 接收消息
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {  // 确保在主线程更新
                switch result {
                case .failure(let error):
                    print("Receiving Error: \(error)")
                    self?.isConnected = false
                case .success(let message):
                    if case .string(let text) = message {
                        self?.handleReceivedMessage(text)
                        self?.receiveMessage()  // 递归调用，继续接收下一条消息
                    }
                }
            }
        }
    }
    
    // 新增: 处理接收到的消息
    private func handleReceivedMessage(_ message: String) {
        switch message {
        case "Connection Established":
            isConnected = true
            connectionError = false
            sendSensorData()  // 开始发送第一条传感器数据
        case "received":
            // 服务器确认数据接收，继续发送下一批数据
            print("received")
            sendSensorData()
        default:
            print("Received: \(message)")
        }
    }
    
    // 发送传感器数据
    private func sendSensorData() {
        let dataMessage = "Data: X=\(Int.random(in: 0...100)), Y=\(Int.random(in: 0...100)), Z=\(Int.random(in: 0...100))"
        sendMessage(message: dataMessage)
        
    }
    
    // 断开连接
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        connectionError = false
        print("WebSocket disconnected")
    }
}
