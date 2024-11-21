(** Abstraction over TCP connection for communicate by NATS protocol.

    Protocol {: https://docs.nats.io/reference/reference-protocols/nats-protocol }. *)

open Unix
open Nats_client

type t = { ic : Lwt_io.input_channel; oc : Lwt_io.output_channel }
(** NATS client connection. *)

exception Connection_refused
(** Raised when failed to make a TCP connection. *)

exception Err_response of string
(** -ERR message. *)

(** Create TCP connection for communicate by NATS protocol. 

    @raises Connection_refused *)
let create ?switch ~host ~port () =
  try%lwt
    let%lwt ic, oc =
      Lwt_io.open_connection @@ ADDR_INET (inet_addr_of_string host, port)
    in

    (* Automatic close socket on switch destroy. *)
    Lwt_switch.add_hook switch (fun () -> Lwt_io.close ic);

    Lwt.return { ic; oc }
  with Unix.Unix_error (Unix.ECONNREFUSED, "connect", "") ->
    raise Connection_refused

let close { oc; _ } =
  (* is it work? *)
  Lwt_io.close oc

exception Invalid_response of string

let receive conn =
  let%lwt line = Lwt_io.read_line conn.ic in
  let m = Incoming_message.Parser.of_line line in

  match m with
  | Incoming_message.MSG msg ->
      (* read payload *)
      let%lwt contents = Lwt_io.read ~count:msg.payload.size conn.ic in
      let%lwt _ = Lwt_io.read ~count:2 conn.ic in

      Lwt.return
      @@ Incoming_message.MSG
           { msg with payload = { msg.payload with contents } }
  | m -> Lwt.return m

module Send = struct
  let writelnf oc pat = Lwt_io.fprintf oc (pat ^^ "\r\n")

  let writeln oc text =
    Lwt_io.write oc text;%lwt
    Lwt_io.write oc "\r\n"

  let writeln' = Fun.flip writeln
  let pong = writeln' "PING"
  let ping = writeln' "PONG"

  let pub ~subject ?reply_to ~payload conn =
    writelnf conn.oc "PUB %s%s %d" subject
      (Option.fold ~none:"" ~some:(Printf.sprintf " %s") reply_to)
      (String.length payload);%lwt
    writeln conn.oc payload

  let sub ~subject ~queue_group ~sid conn =
    writelnf conn.oc "SUB %s%s %s" subject
      (Option.fold ~none:"" ~some:(Printf.sprintf " %s") queue_group)
      sid

  let unsub conn ?max_msgs (sid : Sid.t) =
    writelnf conn.oc "UNSUB %s%s" sid
      (Option.fold max_msgs ~none:"" ~some:(Printf.sprintf " %d"))

  let connect ~json conn =
    (* NOTE: Yojson.Safe.pp gives a bad result.
       TODO: improve performance of JSON encoding (now is bad) *)
    writelnf conn.oc "CONNECT %s" @@ Yojson.Safe.to_string json

  (* TODO: add other *)

  (** @raises Invalid_response when an incoming message in verbose mode is unknown.
      @raises Err_response if a -ERR message was received from a server. *)
  let with_verbose ~verbose conn f =
    f ();%lwt
    if verbose then
      match%lwt receive conn with
      | Incoming_message.OK -> Lwt.return_unit
      | Incoming_message.ERR msg -> raise @@ Err_response msg
      | _ -> raise @@ Invalid_response "expected +OK or -ERR"
    else Lwt.return_unit
end
