class client (connection : Connection.t) =
  object (self)
    method init (msg : Message.Initial.t) =
      Connection.Send.connect ~json:(Message.Initial.to_yojson msg) connection;%lwt
      match%lwt self#receive with
      | Message.Incoming.Info json -> Lwt.return json
      | m ->
          Format.asprintf
            "expected INFO message after connect, but got '%a' message"
            Message.Incoming.pp m
          |> failwith

    method pub ~subject ?reply_to payload =
      Connection.Send.pub ~subject ~reply_to ~payload connection

    method sub ~subject ?(sid : Sid.t option) () =
      let sid = Option.value ~default:(Sid.create 9) sid in
      Connection.Send.sub ~subject ~sid ~queue_group:None connection

    method receive = Connection.receive connection
    method close = Connection.close connection
  end

let make settings =
  let%lwt connection = Connection.create settings in
  Lwt.return @@ new client connection

module Message = Message
module Sid = Sid
module Connection = Connection
