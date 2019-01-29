ruleset io.picolabs.use_twilio_v2 {
  meta {
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
  }
  

 
  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }
  
  rule test_get_messages {
    select when test messages
    
    pre{
      to = event:attr("to").defaultsTo([])
      from = event:attr("from").defaultsTo([])
      page = event:attr("page").defaultsTo([])
      pagesize = event:attr("pagesize").defaultsTo([])
      pagetoken = event:attr("pagetoken").defaultsTo([])
      returnResult = twilio:messages(to, from, page, pagesize, pagetoken)
    }
    
    send_directive("twilio", {"results":returnResult})
    
    
    
    
      
  }
}
