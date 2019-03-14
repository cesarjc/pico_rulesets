ruleset sensor_profile {
  meta {
    provides
      profile_info
    shares 
      profile_info
  }
  global {
    location = function () {
      ent:sensor_location.defaultsTo("My home");  
    }
    
    name = function() {
      ent:sensor_name.defaultsTo("Hello world");  
    }
    
    threshold = function() {
      ent:temp_threshold.defaultsTo("100");  
    }
    
    number = function() {
      ent:sms_number.defaultsTo("3854244861");  
    }
    
    profile_info = function() {
      {
        "location" : location(),
        "name" : name(),
        "threshold" : threshold(),
        "number" : number()
      }
    }
    
  }
  
  rule updated {
    select when sensor profile_updated
    send_directive("updated profile")
    always{
      ent:sensor_location := event:attr("location").defaultsTo(location());
      ent:sensor_name := event:attr("name").defaultsTo(name());
      ent:temp_threshold := event:attr("threshold").defaultsTo(threshold());
      ent:sms_number := event:attr("number").defaultsTo(number());
    }
  }
  
  rule auto_accept {
  select when wrangler inbound_pending_subscription_added
  fired {
    raise wrangler event "pending_subscription_approval"
      attributes event:attrs
  }
}
}
