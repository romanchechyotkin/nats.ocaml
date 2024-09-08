open Nats_client
module Subscription = Subscription
module Connection = Connection

exception Invalid_response = Connection.Invalid_response

class client ~(info : Yojson.Safe.t) ~(connection : Connection.t) =
  object (self)
    val incoming_messages =
      Lwt_stream.from (fun () ->
          let%lwt message = Connection.receive connection in
          Lwt.return_some message)

    val mutable verbose = false

    method init (msg : Message.Initial.t) =
      verbose <- msg.verbose;

      (* I think the fucking verbose mode should be ignored.
         This is the most stupid performance overhead. *)
      Connection.Send.with_verbose ~verbose connection @@ fun () ->
      Connection.Send.connect ~json:(Message.Initial.to_yojson msg) connection;%lwt

      Lwt.return_unit
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

    method info = info

    (* TODO: make drain method, unsub all subscribers  *)
  end

(** @raises Connection.Connection_refused *)
let make settings =
  let%lwt connection = Connection.create settings in
  let%lwt info =
    match%lwt Connection.receive connection with
    | Message.Incoming.Info info -> Lwt.return info
    | _ -> raise @@ Invalid_response "INFO message"
  in
  Lwt.return @@ new client ~info ~connection
