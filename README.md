### The edge drivers developed based on [toddaustin07/MQTTDevices](https://github.com/toddaustin07/MQTTDevices)'s project.

It **doesn't** expose any device that's in [toddaustin07/MQTTDevices](https://github.com/toddaustin07/MQTTDevices). The driver only serves my personal needs for home notification logics.

# Devices supported
- MQTT Notification

  This is a virtual device that implements the ```audioNotification``` and ```audioVolume``` capabilities. You can then add this device as part of the action (Then) to "**Play message on speaker**". When the routine is triggered, a mqtt message will be published with payload ```{volume: integer, uri: string}```. It's your responsibility to implement the real messaging between the physical device upon receiving the mqtt message in your home automation logic. It also supports subscribing mqtt topic with expected payload format ```{volume: integer}``` to update the volume bar in the Smartthings device UI.
