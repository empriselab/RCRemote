import asyncio
import websockets

sensor_data = {
    'OrieX': 0.0,
    'OrieY': 0.0,
    'OrieZ': 0.0,
    'Pitch': 0.0,
    'Roll': 0.0,
    'Gripper': 0.0,
    'Height': 0.0
}

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

def update_sensor_data(data_str):
    # 分割数据并更新字典
    entries = data_str.split(", ")
    for entry in entries:
        key, value = entry.split("=")
        sensor_data[key.strip()] = float(value)
        
async def main():
    async with websockets.serve(handle_client, "192.168.58.100", 1145):
        print("Server running...")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())

