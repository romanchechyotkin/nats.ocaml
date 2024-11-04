module Incoming_message = Message.Incoming
module Initial_message = Message.Initial
module Sid = Sid

let settings ?(echo = false) ?(verbose = false) () =
  Initial_message.{ default with echo; verbose }
