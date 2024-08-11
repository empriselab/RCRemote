import asyncio
import websockets

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
                print(message)
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

async def main():
    async with websockets.serve(handle_client, "192.168.58.100", 1145):
        print("Server running...")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())

