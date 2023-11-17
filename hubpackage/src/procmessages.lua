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

  MQTT Device Driver - handles all MQTT message received for each device type

--]] local log = require "log"
local capabilities = require "st.capabilities"
local json = require "dkjson"
local stutils = require "st.utils"

local sub = require "subscriptions"

local function is_array(t)
  if type(t) ~= "table" then
    return false
  end
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

local function getJSONElement(key, jsonstring)

  if not key or type(key) ~= 'string' then
    log.error('Invalid JSON key string')
    return
  end

  local compound, pos, err = json.decode(jsonstring, 1, nil)

  if not compound then
    if err then
      log.error(string.format('JSON decode error: %s', err))
    end
    return
  end

  local found = false
  local elementslist = {}

  for element in string.gmatch(key, "[^%.]+") do
    table.insert(elementslist, element)
  end

  for el_idx = 1, #elementslist do
    jsonelement = elementslist[el_idx]
    local key = jsonelement:match('^([^%[]+)')
    local array_index = jsonelement:match('%[(%d+)%]$')
    if array_index then

      array_index = tonumber(array_index) + 1;
    end -- adjust for Lua indexes starting at 1
    compound = compound[key]
    if compound == nil then

      break
    end

    if array_index then
      if is_array(compound) then
        if compound[array_index] then
          compound = compound[array_index]
        else
          break
        end
      else
        break
      end
    end

    if type(compound) ~= 'table' then
      if el_idx == #elementslist then
        found = true
      else
        break
      end
    end
  end

  if found then
    return compound
  end
end

local function motionplus(device, msg)

  local lightvalue = getJSONElement(device.preferences.lightkey, msg)
  if type(lightvalue) == 'number' then
    device:emit_event(capabilities.illuminanceMeasurement.illuminance(lightvalue))
  end

  local batteryvalue = getJSONElement(device.preferences.batterykey, msg)
  if type(batteryvalue) == 'number' then
    device:emit_event(capabilities.battery.battery(batteryvalue))
  end

end

local function energy(device, msg)

  local powervalue = getJSONElement(device.preferences.powerkey, msg)
  if type(powervalue) == 'number' then
    if device.preferences.powerunits == 'mwatts' then
      powervalue = powervalue / 1000
    elseif device.preferences.powerunits == 'kwatts' then
      powervalue = powervalue * 1000
    end
    device:emit_event(capabilities.powerMeter.power(powervalue))
  end

end

local function notification(device, msg)

  local volume = getJSONElement('volume', msg)
  if type(volume) == 'number' or type(volume) == 'integer' then
    device:emit_event(capabilities.audioVolume.volume(volume))
  end

end

local function process_message(topic, msg)

  log.debug(string.format("Processing received data msg: %s", msg))
  log.debug(string.format("\tFrom topic: %s", topic))

  local devicelist = sub.determine_devices(topic)
  log.debug('# device matches for topic:', #devicelist)

  if #devicelist > 0 then

    for _, device in ipairs(devicelist) do

      log.debug('Match for', device.label)
      local value
      local dtype = device.device_network_id:match('MQTT_(.+)_+')

      --[[
        Parse the message by our generic preference format, if specified.
        Otherwise leave 'value' as nil to be handled in the custom handlers
        below based on the 'dtype'.
      ]]--
      if (device.preferences.format == 'json') then
        value = getJSONElement(device.preferences.jsonelement, msg)
        if value ~= nil then
          value = tostring(value);
        end
      elseif device.preferences.format == 'string' then
        value = msg
      end

      if value ~= nil then

        -- if (dtype == 'Motion') or (dtype == 'MotionPlus') then
        --   if value == device.preferences.motionactive then
        --     device:emit_event(capabilities.motionSensor.motion.active())
        --   elseif value == device.preferences.motioninactive then
        --     device:emit_event(capabilities.motionSensor.motion.inactive())
        --   else
        --     log.warn('Unconfigured motion value received')
        --   end
        -- end


      --[[
        Custom Handlers Below
      ]]--
      elseif dtype == 'Notification' then

        notification(device, msg)
      else
        log.warn('No valid value found in message; ignoring')
      end
    end
  end
end

return {
  process_message = process_message
}
