import asyncio
import websockets

async def handle_client(websocket, path):
    print("Client connected.")
    try:
        async for message in websocket:
            if message == "Test Connection":
                print(message)
                await websocket.send("Connection Established")
            else:
                # 解析坐标数据
                data = message.split(", ")
                orie_data = data[0].replace("Data: ", "").split(", ")
                orie = tuple(map(float, orie_data))
                pitch = float(data[1].replace("Pitch: ", ""))
                roll = float(data[2].replace("Roll: ", ""))
                gripper = float(data[3].replace("Gripper: ", ""))
                print(message)
    except websockets.ConnectionClosed:
        print("Client disconnected")
    
async def status_monitor():
    while True:
        await asyncio.sleep(5)
        print("Still running...")

async def main():
    server = websockets.serve(handle_client, "192.168.58.101", 1145)
    monitor = status_monitor()
    await asyncio.gather(server, monitor)  # Run both the server and the status monitor concurrently

if __name__ == "__main__":
    print("Start runing...")
    asyncio.run(main())
