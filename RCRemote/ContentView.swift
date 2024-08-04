//
//  ContentView.swift
//  RCRemote
//
//  Created by Qiandao Liu on 7/18/24.
//

import SwiftUI
import CoreMotion

// MARK: Get motion data
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var lastData: CMDeviceMotion? // calculate the change
    private var webSocketManager: WebSocketManager?
    
    // data collected
    @Published var orientationChange = (x: 0.0, y: 0.0, z: 0.0)
    @Published var pitchChange = 0.0
    @Published var rollChange = 0.0
    @Published var gripperValue: Double = 0.0  // gripper depth
    
    // data filter
    @Published var isCollecting = false
    @Published var isGettingOrie = true
    @Published var isGettingPitch = true
    @Published var isGettingRoll = true
    
    // high/low precision
    @Published var highPrecision = false
    
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
    }
    
    // func: start collect data
    // set: fps
    func startSensors() {
        print("Starting sensors...")
        motionManager.deviceMotionUpdateInterval = 1.0 / 1.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            print("Start process data")
            self.processSensorData(data)
        }
    }

    // func: stop collect data
    func stopSensors() {
        print("Stop sensors...")
        motionManager.stopDeviceMotionUpdates()
        lastData = nil
    }

    // func: data filter
    private func processSensorData(_ data: CMDeviceMotion) {
        if self.isGettingOrie {
            self.orientationChange.x += data.attitude.quaternion.x - (self.lastData?.attitude.quaternion.x ?? 0)
            self.orientationChange.y += data.attitude.quaternion.y - (self.lastData?.attitude.quaternion.y ?? 0)
            self.orientationChange.z += data.attitude.quaternion.z - (self.lastData?.attitude.quaternion.z ?? 0)
        }
        if self.isGettingPitch {
            self.pitchChange += data.attitude.pitch - (self.lastData?.attitude.pitch ?? 0)
        }
        if self.isGettingRoll {
            self.rollChange += data.attitude.roll - (self.lastData?.attitude.roll ?? 0)
        }
        
        self.lastData = data  // update changes
        
        // 每次更新数据后立即发送
        if isCollecting {
            sendData()
        }
    }
    
    private func sendData() {
        webSocketManager?.sendSensorData(
            orie: (x: orientationChange.x, y: orientationChange.y, z: orientationChange.z),
            pitch: pitchChange,
            roll: rollChange,
            gripper: gripperValue
        )
    }

    // func: clean the data
    func resetData() {
        print("Reset data...")
        stopSensors()
        orientationChange = (x: 0.0, y: 0.0, z: 0.0)
        pitchChange = 0.0
        rollChange = 0.0
        print("All reset!")
    }
}

// MARK: View Controller
struct ContentView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    @StateObject var motionManager: MotionManager
    
    init() {
        _motionManager = StateObject(wrappedValue: MotionManager(webSocketManager: WebSocketManager()))
    }

    var body: some View {
        GeometryReader { geometry in
            // MARK: Title
            Text("RC - Remote")
                .font(.largeTitle)
                .bold()
                .padding()
                .position(x: geometry.size.width * 0.35, y: geometry.size.height * 0.05)
        
            // MARK: Display Sensor Data
            VStack(spacing: 20) {
                Text("Orie: X \(motionManager.orientationChange.x, specifier: motionManager.highPrecision ? "%.6f" : "%.2f"), Y \(motionManager.orientationChange.y, specifier: motionManager.highPrecision ? "%.6f" : "%.2f"), Z \(motionManager.orientationChange.z, specifier: motionManager.highPrecision ? "%.6f" : "%.2f")")
                Text("Pitch: \(motionManager.pitchChange, specifier: motionManager.highPrecision ? "%.6f" : "%.2f")")
                Text("Roll: \(motionManager.rollChange, specifier: motionManager.highPrecision ? "%.6f" : "%.2f")")
                Text("Gripper: \(Int(motionManager.gripperValue))")
            }
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .font(.body)
            .cornerRadius(5)
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.3)
            
            // MARK: Reset Button
            Button("Reset") {
                motionManager.resetData()
            }
            .padding()
            .background(Color.ownRuby)
            .foregroundColor(.white)
            .font(.title)
            .cornerRadius(8)
            .frame(width: geometry.size.width * 0.9, height: 40)
            .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.55)
            
            // MARK: ON/OFF Toggle Button
            Toggle(isOn: $motionManager.isCollecting) {
                Text("Sensors")
                    .foregroundColor(motionManager.isCollecting ? Color.green : Color.ownBlackTran)
            }
            .padding()
            .background(Color.ownOffWhiteTran)
            .foregroundColor(.ownBlackTran)
            .font(.title)
            .cornerRadius(8)
            .frame(width: geometry.size.width * 0.9, height: 55)
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.65)
            .onChange(of: motionManager.isCollecting) { newValue in
                if newValue {
                    motionManager.startSensors()
                } else {
                    motionManager.stopSensors()
                }
            }
            
            // MARK: high/low precision
            Button("Precise") {
                motionManager.highPrecision.toggle()
            }
            .padding()
            .background(Color.ownBlue)
            .foregroundColor(.white)
            .font(.title)
            .cornerRadius(8)
            .frame(width: geometry.size.width * 0.9, height: 55)
            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.75)
            
            // MARK: gripper status
            // Gripper control
            Slider(value: $motionManager.gripperValue, in: 0...999, step: 1)
                .padding()
                .frame(width: geometry.size.width * 0.6)
                .position(x: geometry.size.width * 0.69, y: geometry.size.height * 0.75)
            
            // MARK: Orie Only
            Button("Orie") {
                // only get orie data
                if motionManager.isCollecting {
                    motionManager.isGettingOrie.toggle()
                }
            }
            .padding()
            .background(Color.ownOffWhite)
            .foregroundColor(motionManager.isGettingOrie ? .green : .ownBlackTran)
            .font(.title)
            .cornerRadius(8)
            .frame(width: geometry.size.width * 0.3, height: 55)
            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.87)
            
            // MARK: Pitch Only
            Button("Pitch") {
                // only get pitch data
                if motionManager.isCollecting {
                    motionManager.isGettingPitch.toggle()
                }
            }
            .padding()
            .background(Color.ownOffWhite)
            .foregroundColor(motionManager.isGettingPitch ? .green : .ownBlackTran)
            .font(.title)
            .cornerRadius(8)
            .frame(width: geometry.size.width * 0.3, height: 55)
            .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.87)
            
            // MARK: Roll Only
            Button("Roll") {
                // only get roll data
                if motionManager.isCollecting {
                    motionManager.isGettingRoll.toggle()
                }
            }
            .padding()
            .background(Color.ownOffWhite)
            .foregroundColor(motionManager.isGettingRoll ? .green : .ownBlackTran)
            .font(.title)
            .cornerRadius(8)
            .frame(width: geometry.size.width * 0.3, height: 55)
            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.87)
        }
    }
}


#Preview {
    ContentView()
}
