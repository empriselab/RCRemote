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

There's no need for you to modify the code, the only thing you may want to change is the refresh rate of sending command to Server, which you can find in Line 38, ContentView:
```
motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
```
The default speed is 60 fps which is good for most of tasks, but you may change it higher.

After that, open the developer mode on your iPhone/iPad. Then connect your iPhone/ipad to macbook with USB cables, trust the devices, 

then on the top middle in Xcode window you will see:

<img width="374" alt="Screenshot 2024-08-26 at 6 15 14 PM" src="https://github.com/user-attachments/assets/49d9a7c7-cdec-429a-8afd-126a406b06a4">

Swich the Build device to iPad or iPhone, then click the Run button left:

<img width="171" alt="Screenshot 2024-08-26 at 6 20 58 PM" src="https://github.com/user-attachments/assets/84648c22-7f72-4474-bbdc-771fa9d9c24b">

First time may not build sccessful since even your mac trust the mobile device, the software still not trusted, so you need to goto Setting - 
