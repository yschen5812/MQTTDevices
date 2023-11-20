### The edge drivers developed based on [toddaustin07/MQTTDevices](https://github.com/toddaustin07/MQTTDevices)'s project.

It **doesn't** include any devices found in [toddaustin07/MQTTDevices](https://github.com/toddaustin07/MQTTDevices). This driver is specifically tailored for my personal home notification logic needs.

# Setup
Please refer to [toddaustin07/MQTTDevices](https://github.com/toddaustin07/MQTTDevices) for setup instructions.

# Devices Supported
- MQTT Notification

  This is a virtual device that implements the ```audioNotification``` and ```audioVolume``` capabilities. You can then add this device as part of the action (Then) to "**Play message on speaker**". When the routine is triggered, a mqtt message will be published with payload ```{volume: integer, uri: string}```. It's your responsibility to implement the real messaging between the physical device upon receiving the mqtt message in your home automation logic. It also supports subscribing mqtt topic with expected payload format ```{volume: integer}``` to update the volume bar in the Smartthings device UI. This is only useful if your speaker device is not officially supported by Smartthings and no 3rd-party edge driver exists, whereas the speaker **does** support API so that you'll then be able to control the physical device within your own home automation system such as HA or Node-Red directly.
  

![95025](https://github.com/yschen5812/MQTTDevices/assets/18079412/5c29179f-5b57-4a82-be25-a02169611a12)
![95024](https://github.com/yschen5812/MQTTDevices/assets/18079412/4098e9c6-fc48-4c1e-a5c9-2391db3cbbf6)
