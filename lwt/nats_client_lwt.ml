open Nats_client
module Subscription = Subscription
module Connection = Connection

type client = {
  connection : Connection.t;
  info : Protocol.info;
  incoming_messages : Protocol.message Lwt_stream.t;
}

let send_initialize_message client (message : Protocol.connect) =
  (* I think the fucking verbose mode should be ignored.
     This is the most stupid performance overhead. *)
  Connection.Send.with_verbose ~verbose:message.verbose client.connection
  @@ fun () ->
  Connection.Send.connect
    ~json:(Protocol.Connection_message.yojson_of_t message)
    client.connection

(** Connect to a NATS server using the [uri] address. 

    @raises Connection.Connection_refused
    @raises Connection.Invalid_response 
    @raises Invalid_argument if [uri] has no host. *)
let connect ?switch ?settings uri =
  let port = Uri.port uri |> Option.value ~default:4222 in
  let host =
    match Uri.host uri with
    | Some host -> host
    | None -> raise (Invalid_argument "host is none")
  in

  let%lwt connection = Connection.create ?switch ~host ~port () in
  let%lwt info =
    match%lwt Connection.receive connection with
    | `INFO info -> Lwt.return info
    | _ -> raise @@ Connection.Invalid_response "INFO message"
  in

  let incoming_messages =
    Lwt_stream.from (fun () ->
        let%lwt message = Connection.receive connection in
        Lwt.return_some message)
  in

  let client = { connection; info; incoming_messages } in

  (match settings with
  | Some settings ->
      send_initialize_message client
        (Protocol.Connection_message.of_poly_variants settings)
  | None -> Lwt.return_unit);%lwt

  Lwt.return client

(** Close socket connection.  *)
let close client = Connection.close client.connection

(** [pub client ~subject ?reply_to payload] publish a message. *)
let pub client ~subject ?reply_to payload =
  Connection.Send.pub ~subject ?reply_to ~payload client.connection

(** [unsub client ?max_msgs sid] unsubscribe from subject. *)
let unsub client ?max_msgs sid =
  Connection.Send.unsub client.connection ?max_msgs sid

(** [sub client ~subject ?sid ()] subscribe on the subject and get stream. *)
let sub ?switch client ~subject ?(sid : Sid.t option) () =
  let sid = Option.value ~default:(Sid.create 9) sid in
  Connection.Send.sub ~subject ~sid ~queue_group:None client.connection;%lwt

  (* auto unsubscribe *)
  Lwt_switch.add_hook switch (fun () -> unsub client sid);

  let messages =
    Lwt_stream.filter_map
      (function
        | `MSG (msg : Protocol.msg)
        (* Is it enough to check a message's SID? *)
          when msg.sid = sid ->
            Some msg
        | _ -> None)
      client.incoming_messages
  in

  Lwt.return Subscription.{ sid; subject; messages }

(* TODO: make drain method, unsub all subscribers  *)

let request client ~subject payload =
  Lwt_switch.with_switch @@ fun switch ->
  let%lwt subscription =
    (* TODO: unique subject for subscription *)
    sub ~switch client ~subject:"for-request-mechanism" ()
  in

  pub client ~subject ~reply_to:"for-request-mechanism" payload;%lwt

  let%lwt incoming_message = Lwt_stream.next subscription.messages in
  Lwt.return incoming_message.payload
