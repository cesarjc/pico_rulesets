ruleset manage_sensors {
  meta {
    
    provides
      sensors,
      temperatures,
      collection_temperature_report,
      reports
    shares
      sensors,
      temperatures,
      collection_temperature_report,
      reports
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
    
    
    reports = function() {
      keys = temp_collection_temperature_report().keys();
      length = keys.length();
      last_report_id = keys[length-1];
      temp_collection_temperature_report().filter(function(v,k){
        (last_report_id - k) < 5
      }) ;
      
    }
    current_report_id = function() {
      ent:current_report_id.defaultsTo(1)
    }
    
    temp_collection_temperature_report = function (){
      ent:temp_collection_temperature_report.defaultsTo(
       {})
    }
    
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
  
rule create_report {
  select when manager create_report
  
  foreach Subscriptions:established("Tx_role","sensor") setting (subscription)
      pre {
        sensor_eci = subscription{"Tx"}.klog("sensor eci:")
        manager_eci = subscription{"Rx"}.klog("manager eci:")
        host = subscription{"Tx_host"}.klog("caught host")
        
      }
        event:send(
          { "eci": sensor_eci,
            "domain": "sensor",
            "type": "create_report",
            "attrs": { 
                      "manager_eci":  manager_eci,
                      "host" : host,
                      "report_id" : current_report_id()
                    } 
          }, host)
          fired{
            
            ent:temp_collection_temperature_report 
            := temp_collection_temperature_report().put(current_report_id(),{
                  "temperature_sensors" : Subscriptions:established("Tx_role","sensor").length(),
                  "responding" : 0,
                  "temperatures" : []
                 
            }) on final;
            ent:current_report_id := (current_report_id().klog("the event id") + 1) on final
          }
  
}

rule process_report {
  select when manager sensor_report_result
  pre{
    temperatures = event:attr("temperatures").klog("manager received temperatures")
    report_id = event:attr("report_id")
    report = temp_collection_temperature_report(){report_id}
  }
  always{
    report{"responding"} = report{"responding"} + 1;
    report{"temperatures"} = report{"temperatures"}.append(temperatures);
    ent:temp_collection_temperature_report := temp_collection_temperature_report().set(report_id,report).klog("setting report");
    // ent:temp_collection_temperature_report := {};
    ent:temp_collection_temperature_report.klog("the new report")
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
      exists = sensors_info().filter(function(v,k){v == sensor_name})
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
