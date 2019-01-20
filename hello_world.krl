ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares hello
  }
  
  global {
    hello = function(obj) {
      msg = "Hello l" + obj;
      msg
    }
  }
  
  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }
  
  rule echo_money {
    
    select when echo monkey
    pre {
      // text = event:attr("name").defaultsTo("monkey").klog("name was")
      text = (event:attr("name")) => event:attr("name") | "monkey"
      }
      
    send_directive("Hello " + text)
    
  }
    
    

  
}
