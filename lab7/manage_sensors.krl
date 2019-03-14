ruleset manage_sensors {
  meta {
    // shares
    provides
      sensors,
      temperatures
    shares
      sensors,
      temperatures
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias Subscriptions
    use module sensor_manager_profile alias profile
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
            auth_token =  keys:twilio{"auth_token"}
  }
  global {
    g_default_number = "3854244861"
    g_default_threshold = "90"
    
    sensors_info = function(){
      ent:sensors_info.defaultsTo({})
    }
    sensors = function() {
      Subscriptions:established("Tx_role","sensor").map(function(subscription){
        {
        "sensor_name" : sensors_info(){subscription{"Id"}},
        "eci" : subscription{"Tx"}
        }
      })
    }
    
    temperatures = function() {
      Subscriptions:established("Tx_role","sensor").map(function(subscription){
        {
        "sensor_name" : sensors_info(){subscription{"Id"}},
        "temperatures" : wrangler:skyQuery(subscription{"Tx"},
                "temperature_store",
                "temperatures",
                {},
                subscription{"Tx_host"})
        }
      })
    }
  }
  

rule subscription_accepted {
  select when wrangler subscription_added
  pre{
    sensor_name = event:attr("name")
    sensor_id = event:attr("Id")
  }
  always{
    ent:sensors_info := sensors_info().put(sensor_id, sensor_name)
  }
  
}

rule subscribe {
  select when sensor subscribe
  pre{
    sensor_name = event:attr("sensor_name").klog("hit subscribe")
    sensor_eci = event:attr("eci")
    host = event:attr("host").defaultsTo(meta:host)
  }

    always{
    raise wrangler event "subscription" attributes{ 
          "name": sensor_name,
          "Tx_host": host,      
          "Rx_role": "controller",
          "Tx_role": "sensor",
          "channel_type": "subscription",
          "wellKnown_Tx": sensor_eci 
       }
    }
}
  
  
  rule process_new_sensor {
   select when sensor new_sensor 
    pre {
      sensor_name = event:attr("sensor_name")
      exists = sensors_info().filter(function(v,k){v == sensor_name})
      
    }
    if exists.length() then
      send_directive("Sensor ready", {"sensor_name":sensor_name})
    notfired {
      raise wrangler event "child_creation"
            attributes { "name": sensor_name,
                         "color": "#ffff00",
                         "rids": ["temperature_store",
                                 "wovyn_base",
                                 "sensor_profile",
                                 "io.picolabs.twilio_v2",
                                 "io.picolabs.use_twilio_v2",
                                 "io.picolabs.lesson_keys"
                                 ] 
                        }
    }
  }
  
  rule process_new_child {
    select when wrangler child_initialized
    pre {
      eci = event:attr("eci").klog("eci here")
      sensor_name = event:attr("rs_attrs"){"name"}
    }
    if sensor_name.klog("found sensor_name")
    then
      event:send({ 
                  "eci": eci, "eid": "initialize-profile",
                   "domain": "sensor", "type": "profile_updated",
                   "attrs": { 
                     "name":  sensor_name,
                     "number" : g_default_number,
                     "threshold" : g_default_threshold
                   } 
                 } )
    fired {
      raise sensor event "subscribe" attributes{
        "sensor_name" :sensor_name,
        "eci" : eci
      }
    }
  }
  
  rule delete_sensor {
    select when sensor unneeded_sensor
    pre {
      sensor_name = event:attr("sensor_name")
      exists = ent:sensors >< sensor_name
    }
    if exists then
      send_directive("deleting_section", {"sensor_name":sensor_name})
    fired {
      raise wrangler event "child_deletion"
        attributes {"name": sensor_name};
        ent:sensors := ent:sensors.delete([sensor_name])
    }
  }
  
  rule process_violation {
    select when sensor threshold_violation
    pre{
      temperature = event:attr("temperature").klog("got to manager violation")
    }
    twilio:send_sms(profile:sms_number(),
                    profile:from_number(),
                    "Temperature violation: " + temperature 
                  )
  }
}
