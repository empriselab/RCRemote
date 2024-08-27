print("""
This script demonstrates the control of a Kinova Gen3 robotic arm with a Robotiq 85 gripper in the RCareWorld environment, controled by RCRemote

What it Implements:
- Initializes the websocket server to start listen commands from IPhone client.
- Initializes the environment with the Kinova Gen3 robotic arm and sets the simulation time step.
- 手机头部向下倾斜（Pitch从0向-0.6降低）表示gripper前进，绝对数值越大，gripper前进变化量越多。
- 手机头部向上抬高（Pitch从0向+0.6增加）表示gripper后退，绝对数值越大，gripper后退变化量越多。
- 手机向左倾斜（Roll从0向-0.6降低）表示gripper向左，绝对数值越大，gripper向左变化量越多。
- 手机向右倾斜（Roll从0向+0.6增加）表示gripper向右，绝对数值越大，gripper向右变化量越多。
- 手机向左的水平旋转（Orie.z从0向+0.3增加）表示gripper水平向左旋转，手机向右的水平旋转（Orie.z从0向-0.3减少）表示gripper水平向右旋转。旋转意味着gripper的方位和robot方位的相对距离固定，做钟表运动。
- height的数值为0的时候，gripper的高度不变，height的数值为正则gripper高度升高，为负则gripper高度降低。绝对数值越大，gripper抬升/降低变化量越多。
- gripper的数值为0-999，当gripper的数值为0-499的时候，调用gripper.GripperClose()。当gripper的数值为500-999的时候，调用gripper.GripperOpen()。
- The script continuously repeats the process by manipulating.

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

def update_sensor_data(data_str):
    entries = data_str.split(", ")
    for entry in entries:
        key, value = entry.split("=")
        sensor_data[key.strip()] = float(value)

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

def apply_robot_movement():
    print("START MOVE ROBOT")

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
        
        # We only use this simple api here. But may achieve more precise motion later.
        if sensor_data['Gripper'] > 500.0:
            print("open")
            gripper.GripperOpen()
        else:
            gripper.GripperClose()
            print("close")

        currentPos = position

        env.step()

def start_websocket_server():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(websockets.serve(handle_client, "192.168.58.104", 1145))
    loop.run_forever()

# Create and execute threads
server_thread = threading.Thread(target=start_websocket_server)
server_thread.start()

robot_thread = threading.Thread(target=apply_robot_movement)
robot_thread.start()

server_thread.join()
robot_thread.join()
