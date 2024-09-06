module Message = Message
module Sid = Sid
module Connection = Connection
module Subscription = Subscription

class client (connection : Connection.t) =
  object (self)
    val incoming_messages =
      Lwt_stream.from (fun () ->
          let%lwt message = Connection.receive connection in
          Lwt.return_some message)

    method init msg =
      Connection.Send.connect ~json:(Message.Initial.to_yojson msg) connection;%lwt
      match%lwt self#receive with
      | Message.Incoming.Info json -> Lwt.return json
      | m ->
          Format.asprintf
            "expected INFO message after connect, but got '%a' message"
            Message.Incoming.pp m
          |> failwith
    (** Initialize communication session.  
        
        {b Warning.} Must be the first message. See example. *)

    method pub ~subject ?reply_to payload =
      Connection.Send.pub ~subject ~reply_to ~payload connection
    (** [pub ~subject ?reply_to payload] publish a message. *)

    method sub ~subject ?(sid : Sid.t option) () =
      let sid = Option.value ~default:(Sid.create 9) sid in
      Connection.Send.sub ~subject ~sid ~queue_group:None connection;%lwt

      Lwt.return
      @@ Lwt_stream.filter_map
           (function
             | Message.Incoming.Msg msg
             (* Is it enough to check a message's SID? *)
               when msg.sid = sid ->
                 Some msg
             | _ -> None)
           self#incoming

    (** [sub ~subject ?sid ()] subscribe on the subject and get stream. *)

    method receive = Connection.receive connection
    (** {b Warning.} Can break the flow of messages? *)

    method close = Connection.close connection
    (** Close socket connection.  *)

    method incoming : Message.Incoming.t Lwt_stream.t =
      (* NOTE: is it okay? (performance issue)
               Anyway, I don't know how to do it any other way :< *)
      Lwt_stream.clone incoming_messages
    (** A stream of all incoming messages.  *)

    (* TODO: make drain method, unsub all subscribers  *)
  end

(** @raises Connection.Connection_refused *)
let make settings =
  let%lwt connection = Connection.create settings in
  Lwt.return @@ new client connection
