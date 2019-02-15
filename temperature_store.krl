ruleset temperature_store {
  meta {
    shares __testing
    provides 
            temperatures,
            threshold_violations,
            inrange_temperatures
    shares 
            temperatures,
            threshold_violations,
            inrange_temperatures
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
    
    temperatures = function() {
      ent:temperatures.defaultsTo([])
    }
    
    threshold_violations = function(){
      ent:violations.defaultsTo([])
    }
    
    inrange_temperatures = function(){
      temperatures().difference(threshold_violations())
    }
    
  }
  
  rule collect_temperatures {
    select when wovyn new_temperature_reading
    always{
      ent:temperatures := ent:temperatures.defaultsTo([]).append([event:attrs])
    }
  }
  
  rule collect_threshold_violations {
    select when wovyn threshold_violation
    always{
      ent:violations := ent:violations.defaultsTo([]).append([event:attrs])
    }
  }
  
  rule clear_temeratures {
    select when sensor reading_reset
    send_directive("Clearing entries!")
    always{
      clear ent:temperatures;
      clear ent:violations;
    }
  }
}
