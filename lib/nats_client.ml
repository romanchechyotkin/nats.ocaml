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
      | Message.Incoming.Ok ->
          Lwt.return
            (Format.asprintf "%a" Message.Incoming.pp Message.Incoming.Ok)
      | Message.Incoming.Ping ->
          Connection.Send.pong connection;%lwt
          Lwt.return
            (Format.asprintf "%a" Message.Incoming.pp Message.Incoming.Ok)
      | m ->
          Format.asprintf
            "expected +OK message after connect, but got '%a' message"
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
             (* TODO: improve matching. Now is just simple incorrect match *)
               when msg.subject = subject || msg.sid = sid ->
                 Some msg
             | _ -> None)
           (Lwt_stream.clone
              incoming_messages
              (* NOTE: is it okay? (performance issue)
                       Anyway, I don't know how to do it any other way :< *))
    (** [sub ~subject ?sid ()] subscribe on the subject and get stream. *)

    method receive = Connection.receive connection
    (** {b Warning.} Can break the flow of messages? *)

    method close = Connection.close connection
    (** Close socket connection.  *)

    method incoming : Message.Incoming.t Lwt_stream.t = incoming_messages
    (** A stream of all incoming messages.  *)

    (* TODO: make drain method, unsub all subscribers  *)
  end

(** @raises Connection.Connection_refused *)
let make settings =
  let%lwt connection = Connection.create settings in
  Lwt.return @@ new client connection
