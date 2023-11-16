--[[
  Copyright 2022, 2023 Todd Austin

  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
  except in compliance with the License. You may obtain a copy of the License at:

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  either express or implied. See the License for the specific language governing permissions
  and limitations under the License.


  DESCRIPTION

  MQTT Device Driver - Capability Command handlers

--]] local log = require "log"
local st_utils = require "st.utils"
local capabilities = require "st.capabilities"
local cosock = require "cosock"
local socket = require "cosock.socket" -- just for time
local json = require "dkjson"

local subs = require "subscriptions"

local function publish_message(device, payload, opt_topic, opt_qos)
  if client and (client_reset_inprogress == false) and payload then

    local pubtopic = opt_topic or device.preferences.pubtopic
    local pubqos = opt_qos or device.preferences.qos:match('qos(%d)$')

    assert(client:publish{
      topic = pubtopic,
      payload = payload,
      qos = tonumber(pubqos)
    })

    log.debug(string.format('Message "%s" published to topic %s with qos=%d', payload, pubtopic, tonumber(pubqos)))

  end

end

local function handle_refresh(driver, device, command)

  log.info('Refresh requested')

  if device.device_network_id:find('Master', 1, 'plaintext') then
    creator_device:emit_event(cap_createdev.deviceType(' ', {
      visibility = {
        displayed = false
      }
    }))
    init_mqtt(device)
  else
    subs.mqtt_subscribe(device)
  end

end

local function create_device(driver, dtype)

  if dtype then

    local PROFILE = typemeta[dtype].profile
    if PROFILE then

      local MFG_NAME = 'SmartThings Community'
      local MODEL = 'mqtttdev_' .. dtype
      local LABEL = 'MQTT ' .. dtype
      local ID = 'MQTT_' .. dtype .. '_' .. tostring(socket.gettime())

      log.info(string.format('Creating new device: label=<%s>, id=<%s>', LABEL, ID))
      if clearcreatemsg_timer then
        driver:cancel_timer(clearcreatemsg_timer)
      end

      local create_device_msg = {
        type = "LAN",
        device_network_id = ID,
        label = LABEL,
        profile = PROFILE,
        manufacturer = MFG_NAME,
        model = MODEL,
        vendor_provided_label = LABEL
      }

      assert(driver:try_create_device(create_device_msg), "failed to create device")
    end
  end
end

local function handle_createdevice(driver, device, command)

  log.debug("Device type selection: ", command.args.value)

  device:emit_event(cap_createdev.deviceType('Creating device...'))

  create_device(driver, command.args.value)

end

local function disptable(table, tab, maxlevels, currlevel)

  if not currlevel then

    currlevel = 0;
  end
  currlevel = currlevel + 1
  for key, value in pairs(table) do
    if type(key) ~= 'table' then
      log.debug(tab .. '  ' .. key, value)
    else
      log.debug(tab .. '  ', key, value)
    end
    if (type(value) == 'table') and (currlevel < maxlevels) then
      disptable(value, '  ' .. tab, maxlevels, currlevel)
    end
  end
end

local function handle_custompublish(driver, device, command)

  -- disptable(command, '  ', 8)

  log.debug(string.format('%s command Received; topic = %s; msg = %s; qos = %d (%s)', command.command,
    command.args.topic, command.args.message, command.args.qos, type(command.args.qos)))

  publish_message(device, command.args.message, command.args.topic, command.args.qos)

end

local function handle_audio_notification(driver, device, command)
  if device.device_network_id:match('MQTT_Notification_+') then

    local msgobj = {}
    msgobj['uri'] = command.args.uri

    local volume_level = device:get_latest_state("main", capabilities.audioVolume.ID,
      capabilities.audioVolume.volume.NAME) or 50
    msgobj['volume'] = st_utils.clamp_value(volume_level, 0, 100)

    sendmsg = json.encode(msgobj, {
      indent = false
    })
    publish_message(device, sendmsg)
  end
end

local function handle_set_speaker_volume(driver, device, command)
  local newVolume = st_utils.clamp_value(command.args.volume, 0, 100)
  device:emit_event(capabilities.audioVolume.volume(newVolume))

  if device.device_network_id:match('MQTT_Notification_+') then
    local msgobj = {
      ['volume'] = newVolume
    }
    sendmsg = json.encode(msgobj, {
      indent = false
    })
    publish_message(device, sendmsg)
  end
end

return {
  handle_refresh = handle_refresh,
  handle_createdevice = handle_createdevice,
  handle_custompublish = handle_custompublish,
  handle_audio_notification = handle_audio_notification,
  handle_set_speaker_volume = handle_set_speaker_volume
}

