ruleset io.picolabs.twilio_v2 {
  meta {
    configure using account_sid = ""
                    auth_token = ""
    provides
        send_sms,
        messages,
        read
    logging on
  }
 
  global {
    send_sms = defaction(to, from, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json", form = {
                "From":from,
                "To":to,
                "Body":message
            })
    }
    
    messages = function(to, from, page, pagesize, pagetoken) {
      
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>;
      
      json_from_url = http:get(base_url + "Messages.json", 
              qs = {
                "To" : to,
                "From" : from,
                "Page" : page,
                "PageSize" : pagesize,
                "PageToken" : pagetoken
                
             }){"content"}.decode();
      json_from_url
    
    }
    
    
  }
}
