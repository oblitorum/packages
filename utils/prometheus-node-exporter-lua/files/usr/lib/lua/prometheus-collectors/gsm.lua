local uci = require 'uci'.cursor()
local periphery = require('periphery')
local Serial = periphery.Serial

local function scrape()
  local metric_gsm_signal_strength = metric("gsm_signal_strength","gauge")

  uci:foreach('prometheus-node-exporter-lua', 'gsm-collector', function (config)
    local serial_port = '/dev/ttyUSB0'

    if hasKey(config, "serial_port") and config.serial_port.match("%S") != nil then
      serial_port = config['serial_port']
    end

    local serial = Serial(serial_port, 115200)

    serial:write("AT+CSQ")
    serial:flush()

    local buf = serial:read(128, 500)
    if string.match(buf, "\r\nOK\r\n") != nil then
      local rssi = string.gsub(buf, "+CSQ: (%d+),%d+", "%1")
      local dBm = (tonumber(rssi) * 2) - 113
      local labels = {
        name = config['.name'],
      }

      metric_gsm_signal_strength(labels, dBm)
    end

    serial:close()
  end)
end

return { scrape = scrape }
