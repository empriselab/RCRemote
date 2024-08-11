//
//  ContentView.swift
//  RCRemote
//
//  Created by Qiandao Liu on 7/18/24.
//

import Foundation
import SwiftUI
import CoreMotion

// MARK: Get motion data
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var lastData: CMDeviceMotion? // calculate the change
    var webSocketManager: WebSocketManager?
    
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
    
    // func: start collect data
    // set: fps
    func startSensors() {
        print("Starting sensors...")
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
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
        
        webSocketManager?.updateData(orieX: self.orientationChange.x, orieY: self.orientationChange.y, orieZ: self.orientationChange.z, pitch: self.pitchChange, roll: self.rollChange, gripper: self.gripperValue)
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
    @State private var serverAddress: String = ""
    @State private var serverPort: String = ""
    
    init() {
        let motionManager = MotionManager()
        _motionManager = StateObject(wrappedValue: motionManager)
    }

    var body: some View {
        
        // Preuse webSocketManager in contentView
        Text("")
            .onAppear {
                self.motionManager.webSocketManager = self.webSocketManager
            }
        
        GeometryReader { geometry in
            // MARK: Title
            Text("RC - Remote")
                .font(.largeTitle)
                .bold()
                .padding()
                .position(x: geometry.size.width * 0.35, y: geometry.size.height * 0.05)
        
            // Server address input
            TextField("Address", text: $serverAddress)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: geometry.size.width * 0.7, height: 40)
                .position(x: geometry.size.width * 0.4, y: geometry.size.height * 0.13)
            
            // Server port input
            TextField("Port", text: $serverPort)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: geometry.size.width * 0.7, height: 40)
                .position(x: geometry.size.width * 0.4, y: geometry.size.height * 0.19)
            
            // Refresh/connect button
            Button("🔄") {
                webSocketManager.connect(address: serverAddress, port: serverPort)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 22)

            .background(Color.ownWhite)
            .cornerRadius(8)
            .font(.system(size: 35, weight: .bold, design: .default))
            .frame(width: geometry.size.width * 0.9, height: 40)
            .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.16)
            

            
            // MARK: Display Sensor Data
            VStack(spacing: 20) {
                Text("Orie: X \(motionManager.orientationChange.x, specifier: motionManager.highPrecision ? "%.6f" : "%.3f"), Y \(motionManager.orientationChange.y, specifier: motionManager.highPrecision ? "%.6f" : "%.3f"), Z \(motionManager.orientationChange.z, specifier: motionManager.highPrecision ? "%.6f" : "%.3f")")
                Text("Pitch: \(motionManager.pitchChange, specifier: motionManager.highPrecision ? "%.6f" : "%.3f")")
                Text("Roll: \(motionManager.rollChange, specifier: motionManager.highPrecision ? "%.6f" : "%.3f")")
                Text("Gripper: \(Int(motionManager.gripperValue))")
            }
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .font(.body)
            .cornerRadius(5)
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.37)
            
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
                webSocketManager.updatePrecision(high: motionManager.highPrecision)
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
