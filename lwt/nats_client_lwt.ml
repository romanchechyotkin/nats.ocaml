open Nats_client
module Subscription = Subscription
module Connection = Connection

type client = {
  connection : Connection.t;
  info : Incoming_message.INFO.t;
  incoming_messages : Incoming_message.t Lwt_stream.t;
}

let send_initialize_message client (message : Initial_message.t) =
  (* I think the fucking verbose mode should be ignored.
     This is the most stupid performance overhead. *)
  Connection.Send.with_verbose ~verbose:message.verbose client.connection
  @@ fun () ->
  Connection.Send.connect
    ~json:(Initial_message.to_yojson message)
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
    | Incoming_message.INFO info -> Lwt.return info
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
      send_initialize_message client (Initial_message.of_poly_variants settings)
  | None -> Lwt.return_unit);%lwt

  Lwt.return client

(** Close socket connection.  *)
let close client = Connection.close client.connection

(** [pub ~subject ?reply_to payload] publish a message. *)
let pub client ~subject ?reply_to payload =
  Connection.Send.pub ~subject ~reply_to ~payload client.connection

(** [sub ~subject ?sid ()] subscribe on the subject and get stream. *)
let sub client ~subject ?(sid : Sid.t option) () =
  let sid = Option.value ~default:(Sid.create 9) sid in
  Connection.Send.sub ~subject ~sid ~queue_group:None client.connection;%lwt

  Lwt.return
  @@ Lwt_stream.filter_map
       (function
         | Incoming_message.MSG msg
         (* Is it enough to check a message's SID? *)
           when msg.sid = sid ->
             Some msg
         | _ -> None)
       client.incoming_messages

(* TODO: make drain method, unsub all subscribers  *)
