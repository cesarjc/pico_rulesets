ruleset wovyn_base {
  meta {
    shares __testing
    logging on
    use module sensor_profile alias profile
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
            auth_token =  keys:twilio{"auth_token"}
  }
  global {
    fromNumber = "8019198946"
  }
  
  rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing")
    pre {
      temperature = event:attr("genericThing"){"data"}{"temperature"}[0]{"temperatureF"}
      .klog("New received temp: ")
    }
    send_directive("New temperature reading")  
    always{
      
        raise wovyn event "new_temperature_reading"
        attributes { "temperature": temperature, "timestamp" : time:now() }
    }
  }
  
  
  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attr("temperature")
    }
    if temperature > profile:profile_info().get("threshold") then
    
     send_directive("Threshold violation")  
    fired{
      
      raise wovyn event "threshold_violation"
        attributes { "temperature": temperature, 
        "timestamp" : event:attr("timestamp").defaultsTo([]) }
    }
    
  }
  
  rule threshold_notification {
    select when wovyn threshold_violation
    pre{
      temp = event:attr("temperature").klog("sending new text for temp: ")
    }
    twilio:send_sms(profile:profile_info().get("number"),
                    fromNumber,
                    "Temperature violation: " + temp 
                  )
  }
  
  
  
}
