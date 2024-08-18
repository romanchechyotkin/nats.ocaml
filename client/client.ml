class client (connection : Connection.t) =
  object
    method init (initial_message : Message.Initial.t) =
      Connection.send_message connection
        (Message.Connect (Message.Initial.to_yojson initial_message));%lwt
      Connection.recv_response connection

    method pub ~subject ?reply_to payload =
      Connection.send_message connection
        Message.(Pub { subject; reply_to; payload })

    method sub ~subject ?(sid : Sid.t option) () =
      let sid = Option.value ~default:(Sid.create 9) sid in
      Connection.send_message connection
        (Message.Sub { subject; sid; queue_group = None })

    method receive_response = Connection.recv_response connection
    method close = Connection.close connection
  end

let make settings =
  let%lwt connection = Connection.create settings in
  Lwt.return @@ new client connection
