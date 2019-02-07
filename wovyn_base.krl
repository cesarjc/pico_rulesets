ruleset wovyn_base {
  meta {
    shares __testing
    logging on
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
            auth_token =  keys:twilio{"auth_token"}
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    temperature_threshold = 70
    toNumber = "3854244861"
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
    if temperature > temperature_threshold then
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
    twilio:send_sms(toNumber,
                    fromNumber,
                    "Temperature violation: " + temp 
                  )
  }
  
  
  
}
