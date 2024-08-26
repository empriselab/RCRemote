# RCRemote
Wireless IOS software to control the robot motion by WIFI

Welcome to RCRemote, here's the several steps for your setup:

## Hardware Requirements
This project has two parts: Client(IPhone) & Server(Computer to run the Unity environment)
* Client: Generally, you can run the software on any IOS devices like IPhone or IPad or some other Apple products with accelerator and CoreMotion sensors. Since the app is not on Apple Store, so you may need an extra macbook/Imac to download the software and transfer it to your mobile devices.
* Server: Since the server is build on RCareWorld Unity executable file right now, so the requirement is the same as the requirements we have for PhyRC Challenge, which you can find it here: https://github.com/empriselab/RCareWorld/tree/phy-robo-care. Ubuntu system is recommanded, but can also run 

### Setup
First guide to the RCareWorld repository https://github.com/empriselab/RCareWorld/tree/phy-robo-care, follow the README to get the environmnet we need.

After your environment all set (make sure switch the branch to phy-robo-care), then get the Server code: 
```
git clone https://github.com/empriselab/RCRemote.git
git checkout Server
```
In the Server branch, you will see a python file named: example_kinova_gen3_move.py which is the example file to show how to import WebSocket and robot command to Unity, you can copy it directly to RCareWorld/pyrcareworld/pyrcareworld/demo/examples/ or learn the stategy to control and robot in any unity executable file.

About the client, first you have to find a macbook/Imac which can install Xcode 15.0, Xcode is a IOS software used to build IOS software which uses Swift language, After you install the Xcode 15.0, command:
```
git clone https://github.com/empriselab/RCRemote.git
git checkout Software
```
After that, open the repository in Xcode, the structures looks like that:

<img width="264" alt="Screenshot 2024-08-26 at 6 02 21 PM" src="https://github.com/user-attachments/assets/01e15cd5-743a-4218-b28f-da8fa19cc0a8">

There's no need for you to modify the code, the only thing you may want to change is the refresh rate of sending command to Server, which you can find in Line 38, ContentView:
```
motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
```
The default speed is 60 fps which is good for most of tasks, but you may change it higher.

