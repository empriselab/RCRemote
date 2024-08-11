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
    @Published var highPrecision = false  // 控制数据精度
    @Published var networkDelay: Int = 0  // 网络延迟，以毫秒为单位
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private var lastSendTime: Date?  // 记录上次发送数据的时间
    
    // Properties for sensor data
    @Published var orientationChange = (x: 0.0, y: 0.0, z: 0.0)
    @Published var pitchChange = 0.0
    @Published var rollChange = 0.0
    @Published var gripperValue = 0.0
    @Published var height = 0.0  // 新增: 用于控制高度的变量
    
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
            if let lastSendTime = lastSendTime {
                let delay = Date().timeIntervalSince(lastSendTime)
                DispatchQueue.main.async {
                    self.networkDelay = Int(delay * 1000)  // 转换为毫秒
                }
            }
            sendSensorData()
        default:
            print("Received: \(message)")
        }
    }
    
    // 方法来更新精度
    func updatePrecision(high: Bool) {
        highPrecision = high
    }
    
    // 发送传感器数据
    private func sendSensorData() {
        let format = highPrecision ? "%.6f" : "%.3f"
        let dataMessage = "Data: OrieX=\(String(format: format, orientationChange.x)), OrieY=\(String(format: format, orientationChange.y)), OrieZ=\(String(format: format, orientationChange.z)), Pitch=\(String(format: format, pitchChange)), Roll=\(String(format: format, rollChange)), Gripper=\(Int(gripperValue)), Height=\(String(format: format, height))"
        lastSendTime = Date()  // 更新发送时间
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
