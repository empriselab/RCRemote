print("""
This script demonstrates the control of a Kinova Gen3 robotic arm with a Robotiq 85 gripper in the RCareWorld environment, controled by RCRemote

What it Implements:
- Initializes the websocket server to start listen commands from IPhone client.
- Initializes the environment with the Kinova Gen3 robotic arm and sets the simulation time step.

Required Operations:
- Loop: The script continuously performs pick-and-place operations in a loop.
- Object Manipulation: Creates, moves, and destroys rigid body box objects.
- Robot Control: Executes IK movements and gripper operations to complete the task.
""")

import threading
import asyncio
import websockets
import random
import os
import sys
import pyrcareworld.attributes as attr

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from pyrcareworld.demo import executable_path
from pyrcareworld.envs.base_env import RCareWorld

# Sensor data storage
sensor_data = {
    'OrieX': 0.0, 'OrieY': 0.0, 'OrieZ': 0.0,
    'Pitch': 0.0, 'Roll': 0.0, 'Gripper': 0.0, 'Height': 0.0
}

# Initialize the environment with the specified scene file
player_path = os.path.join(executable_path, "../executable/Player/Player.x86_64")

# Initialize the environment with the specified assets and set the time step
env = RCareWorld(assets=["kinova_gen3_robotiq85"], executable_file="../executable/Player/Player.x86_64")
env.SetTimeStep(0.005)

# Create an instance of the Franka Panda robot and set its IK target offset
robot = env.InstanceObject(name="kinova_gen3_robotiq85", id=123456, attr_type=attr.ControllerAttr)
robot.SetPosition([0,0,0])
env.step()

# Get the gripper attribute and open the gripper
gripper = env.GetAttr(1234560)
gripper.GripperOpen()

# Move and rotate the robot to the initial position
robot.IKTargetDoMove(position=[0, 0.5, 0.5], duration=0, speed_based=False)
robot.IKTargetDoRotate(rotation=[0, 45, 180], duration=0, speed_based=False)
robot.WaitDo()

# Create two Rigidbody_Box instances with random positions
box1 = env.InstanceObject(name="Rigidbody_Box", id=111111, attr_type=attr.RigidbodyAttr)
box1.SetTransform(
    position=[random.uniform(-0.5, -0.3), 0.03, random.uniform(0.3, 0.5)],
    scale=[0.4, 0.4, 0.4],
)
box2 = env.InstanceObject(name="Rigidbody_Box", id=222222, attr_type=attr.RigidbodyAttr)
box2.SetTransform(
    position=[random.uniform(0.3, 0.5), 0.03, random.uniform(0.3, 0.5)],
    scale=[0.04, 0.04, 0.04],
)

# Split the message from Client to seperate data
def update_sensor_data(data_str):
    entries = data_str.split(", ")
    for entry in entries:
        key, value = entry.split("=")
        sensor_data[key.strip()] = float(value)

# Heartbeat func, send "ping" to Client per 10 seconds to prevent disconnection
async def heartbeat(websocket, interval=10):
    try:
        while websocket.open:
            await asyncio.sleep(interval)
            await websocket.send("ping")
            print("Heartbeat sent.")
    except asyncio.CancelledError:
        print("Heartbeat task cancelled.")
    except websockets.ConnectionClosed:
        print("WebSocket closed, stopping heartbeat.")

# Receive message from client and give different response depend on the content
# If message is Data, call func update_sensor_data, response a "received" to Client.
# If message is "Test Connection", response a "Connection Established" to Client.
async def handle_client(websocket, path):
    print("Client connected.")
    heartbeat_task = asyncio.create_task(heartbeat(websocket))
    try:
        async for message in websocket:
            if message.startswith("Data: "):
                update_sensor_data(message[len("Data: "):])
                print(sensor_data)
                await websocket.send("received")
            elif message == "Test Connection":
                print("Connection test received.")
                await websocket.send("Connection Established")
            else:
                print("Received unknown message.")
    except websockets.ConnectionClosed as e:
        print("Client disconnected with exception")
    finally:
        heartbeat_task.cancel()

# Transfer data to robot motion command
def apply_robot_movement():
    print("START MOVE ROBOT")

    # Get robot position first.
    # should be change to a new api like gripper.data.get("position") to get gripper position instead of robot.
    currentPos = robot.data.get("position")

    while True:
        dx = sensor_data['Roll'] * 0.005
        dy = sensor_data['Height'] * -0.001
        dz = sensor_data['Pitch'] * -0.005

        position = currentPos
        position[0] = position[0] + dx
        position[1] = position[1] + dy
        position[2] = position[2] + dz

        robot.IKTargetDoMove(position=position, duration=0.0, speed_based=False)
        
        # We only use this simple api here. But you may achieve more precise motion later.
        if sensor_data['Gripper'] > 500.0:
            print("open")
            gripper.GripperOpen()
        else:
            gripper.GripperClose()
            print("close")

        # Update position once each step
        currentPos = position

        env.step()

# Start the Websocket Looping to keep get/send message.
def start_websocket_server():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(websockets.serve(handle_client, "192.168.58.104", 1145))  # Change the address to your computer's IPv4 address.
    loop.run_forever()

# Create and execute threads
server_thread = threading.Thread(target=start_websocket_server)
server_thread.start()

robot_thread = threading.Thread(target=apply_robot_movement)
robot_thread.start()

server_thread.join()
robot_thread.join()
