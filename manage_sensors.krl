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
  }
  global {
    g_default_number = "3854244861"
    g_default_threshold = "90"
    
    sensors = function() {
      ent:sensors.defaultsTo({})
    }
    
    temperatures = function() {
      sensors().map(function(eci, sensor_name) {
        wrangler:skyQuery(eci,"temperature_store","temperatures",{})
      })
    }
  }
  
  
  
  rule process_new_sensor {
   select when sensor new_sensor 
    pre {
      sensor_name = event:attr("sensor_name")
      exists = ent:sensors >< sensor_id
      // eci = meta:eci
    }
    if exists then
      send_directive("Sensor ready", {"sensor_name":sensor_name})
    notfired {
      // ent:sensors := ent:sensors.defaultsTo({}).put(sensor_name, eci);
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
      eci = event:attr("eci")
      sensor_name = event:attr("rs_attrs"){"name"}
    }
    if sensor_name.klog("found sensor_id")
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
      ent:sensors := ent:sensors.defaultsTo({}).put(sensor_name, eci);
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
}
