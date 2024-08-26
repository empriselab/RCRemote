# RCRemote
Wireless IOS software to control the robot motion by WIFI

Welcome to RCRemote, here's the several steps for your setup:

## Hardware Requirements
This project has two parts: Client(IPhone) & Server(Computer to run the Unity environment)
* Client: Generally, you can run the software on any iOS devices like iPhone or iPad or some other Apple products with accelerator and CoreMotion sensors. Updates iPhone to iOS 13 or higher. Since the app is not on Apple Store, so you may need an extra macbook/iMac to download the software and transfer it to your mobile devices.
* Server: Since the server is build on RCareWorld Unity executable file right now, so the requirement is the same as the requirements we have for PhyRC Challenge, which you can find it here: https://github.com/empriselab/RCareWorld/tree/phy-robo-care. Ubuntu system is recommanded, but can also run 

### Setup
First guide to the RCareWorld repository https://github.com/empriselab/RCareWorld/tree/phy-robo-care, follow the README to get the environmnet we need.

After your environment all set (make sure switch the branch to phy-robo-care), then get the Server code: 
```
git clone https://github.com/empriselab/RCRemote.git
git checkout Server
```
In the Server branch, you will see a python file named: example_kinova_gen3_move.py which is the example file to show how to import WebSocket and robot command to Unity, you can copy it directly to RCareWorld/pyrcareworld/pyrcareworld/demo/examples/ or learn the stategy to control and robot in any unity executable file.

About the client, first you have to find a macbook/iMac which can install Xcode 11.0 or higher, Xcode is a IOS software used to build IOS software which uses Swift language, After you install the Xcode 11.0 or higher, command:
```
git clone https://github.com/empriselab/RCRemote.git
git checkout Software
```
After that, open the repository in Xcode, the structures looks like that:

<img width="264" alt="Screenshot 2024-08-26 at 6 02 21 PM" src="https://github.com/user-attachments/assets/01e15cd5-743a-4218-b28f-da8fa19cc0a8">

Click the top blue RCRemote, in the setting page, choose the Personal team, you can use same Apple ID as your iPhone:

<img width="1014" alt="Screenshot 2024-08-26 at 6 27 24 PM" src="https://github.com/user-attachments/assets/e163a3b6-4f94-4339-95e4-7bb8b5a791bf">

There's no need for you to modify the code, the only thing you may want to change is the refresh rate of sending command to Server, which you can find in ContentView, Line 38:
```
motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
```
The default speed is 60 fps which is good for most of tasks, but you may change it higher.

After that, open the developer mode on your iPhone/iPad. Then connect your iPhone/ipad to macbook with USB cables, trust the devices, 

then on the top middle in Xcode window you will see:

<img width="374" alt="Screenshot 2024-08-26 at 6 15 14 PM" src="https://github.com/user-attachments/assets/49d9a7c7-cdec-429a-8afd-126a406b06a4">

Swich the Build device to iPad or iPhone, then click the Run button left:

<img width="171" alt="Screenshot 2024-08-26 at 6 20 58 PM" src="https://github.com/user-attachments/assets/84648c22-7f72-4474-bbdc-771fa9d9c24b">

First time may not build sccessful since even your mac trust the mobile device, the software still not trusted, so you need go to Settings - Privacy & Security to allow the installment. Then run the software again, you will see the software icon is already on your iPhone/iPad, witch means you've install the software on your device:

![IMG_472FE6B9C146-1](https://github.com/user-attachments/assets/b8e67e76-c32a-4508-9883-889769a16bbf)

Congratulations! The setup part is all set~

### Connection
To connect iPhone/iPad to Unity scene to control robot, open Server/Client which one first is not important, you do following steps:

##### For Server
For Server, we first need to find the address and port for sending message.

For Windows system, use command:
```
ipconfig
```
The address is line of number followed 'IPv4', for example: 
```
IPv4 Address. . . . . . . . . . . : 192.168.58.104
```
Then the address is 192.168.58.104 in this example.

For Ubuntu system, use command:
```
ifconfig
```
The address is line of number followed 'inet', for example:
```
wlp4s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.58.104  netmask 255.255.255.0  broadcast 192.168.58.255
```
Then the address is 192.168.58.104 in this example.

After you find the address, open example_kinova_gen3_move.py, in Line 141:
```
loop.run_until_complete(websockets.serve(handle_client, "192.168.58.104", 1145))
```
Replace the 192.168.58.104 to your own address, number 1145 is the port, you can also modify the port to control multiple robot in different Unity scene.

Then save the file, command:
```
conda activate rcareworld
cd RCareWorld/pyrcareworld/pyrcareworld/demo/examples




