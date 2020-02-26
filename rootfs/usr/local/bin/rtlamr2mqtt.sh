#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: rtlamr2mqtt
# Runs rtlamr and sends results to mqtt
# ==============================================================================

declare -a mosquitto_options
declare mqtt_host
declare mqtt_port
declare mqtt_ca_cert
declare mqtt_topic_base

declare -a rtlamr_options
declare rtlamr_filterid
declare rtlamr_filtertype
declare rtlamr_msgtype

declare meter_id

if bashio::config.has_value 'mqtt_host'; then
  mqtt_host = $(bashio::config 'mqtt_host')
  mosquitto_options+=("-h ${mqtt_host}")

  bashio::log.info "[-] MQTT Host ${mqtt_host}"
fi

if bashio::config.has_value 'mqtt_port'; then
  mqtt_port = $(bashio::config 'mqtt_port')
  mosquitto_options+=("-p ${mqtt_port}")

  bashio::log.info "[-] MQTT Port ${mqtt_port}"
fi

if bashio::config.true 'tls'; then
  # Identrust cross-signed CA cert needed by the java keystore for import.
  # Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
  mqtt_ca_cert="/usr/local/share/rtlamr2mqtt/DST_Root_CA_X3.pem"

  mosquitto_options+=("--tls-version tlsv1.2")
  mosquitto_options+=("--cafile ${mqtt_ca_cert}")

  bashio::log.info "[-] Using MQTT TLS with CA cert ${mqtt_ca_cert}"
fi

mosquitto_options+=("-V mqttv311")
mosquitto_options+=("-i rtlamr2mqtt")
mosquitto_options+=("-l")

if bashio::config.has_value 'mqtt_topic_base'; then
  mqtt_topic_base = $(bashio::config 'mqtt_topic_base')
else
  mqtt_topic_base = "homeassistant/sensor/rtlamr2mqtt/"
fi
bashio::log.info "[-] MQTT Topic Base ${mqtt_topic_base}"

if bashio::config.has_value 'rtlamr_filterid'; then
  rtlamr_filterid = $(bashio::config 'rtlamr_filterid')
  rtlamr_options+=("-filterid=${rtlamr_filterid}")

  bashio::log.info "[-] RTLAMR filter id(s) ${rtlamr_filterid}"
fi

if bashio::config.has_value 'rtlamr_filtertype'; then
  rtlamr_filtertype = $(bashio::config 'rtlamr_filtertype')
  rtlamr_options+=("-filtertype=${rtlamr_filtertype}")

  bashio::log.info "[-] RTLAMR filter type(s) ${rtlamr_filtertype}"
fi

rtlamr_options+=("-format=json")

if bashio::config.has_value 'rtlamr_msgtype'; then
  rtlamr_msgtype = $(bashio::config 'rtlamr_msgtype')
  rtlamr_options+=("-msgtype=${rtlamr_msgtype}")

  bashio::log.info "[-] RTLAMR message type(s) ${rtlamr_msgtype}"
fi

/usr/local/bin/rtlamr "${rtlamr_options[@]}" | while read line; do
  meter_id="$(echo $line | jq --raw-output '.Message.ID')"

  mqtt_topic=$mqtt_topic_base

  if [ ${#meter_id} ] >0; then
    mqtt_topic="${mqtt_topic}/${meter_id}"
  fi

  bashio::log.info "[.] ${line}"
  echo $line | /usr/bin/mosquitto_pub "${mosquitto_options[@]}" "-t ${mqtt_topic}"
done
