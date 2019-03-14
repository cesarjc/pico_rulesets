ruleset sensor_manager_profile {
  meta {
    provides
      sms_number,
      from_number
    shares 
      sms_number,
      from_number
  }
  global {
    
    
    sms_number = function() {
      ent:sms_number.defaultsTo("3854244861");  
    }
    from_number = function(){
      ent:from_number.defaultsTo("8019198946");  
    }
  }
  
  
  
}
