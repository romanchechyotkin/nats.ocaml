(** Abstraction over TCP connection for communicate by NATS protocol.

    Protocol {: https://docs.nats.io/reference/reference-protocols/nats-protocol }. *)

open Unix
open Nats_client

type t = {
  ic : Lwt_io.input_channel;
  oc : Lwt_io.output_channel;
  socket : Lwt_unix.file_descr;
}
(** NATS client connection. *)

exception Connection_refused
(** Raised when failed to make a TCP connection. *)

let crlf = "\r\n"

module Send = struct
  let pong conn = Lwt_io.write conn.oc (Printf.sprintf "PONG%s" crlf)
  let ping conn = Lwt_io.write conn.oc (Printf.sprintf "PING%s" crlf)

  let pub ~subject ~reply_to ~payload conn =
    Lwt_io.fprintf conn.oc "PUB %s%s %d%s%s%s" subject
      (Option.fold ~none:"" ~some:(Printf.sprintf " %s") reply_to)
      (String.length payload) crlf payload crlf

  let sub ~subject ~queue_group ~sid conn =
    Lwt_io.fprintf conn.oc "SUB %s%s %s%s" subject
      (Option.fold ~none:"" ~some:(Printf.sprintf " %s") queue_group)
      sid crlf

  let connect ~json conn =
    (* NOTE: Yojson.Safe.pp gives a bad result.
       TODO: improve performance of JSON encoding (now is bad) *)
    Lwt_io.fprintf conn.oc "CONNECT %s%s" (Yojson.Safe.to_string json) crlf

  (* TODO: add other *)
end

let receive conn =
  let%lwt line = Lwt_io.read_line conn.ic in
  let m = Message.Incoming.Parser.of_line line in

  match m with
  | Message.Incoming.Msg msg ->
      (* read payload *)
      let%lwt contents = Lwt_io.read ~count:msg.payload.size conn.ic in
      let%lwt _ = Lwt_io.read ~count:2 conn.ic in

      Lwt.return
      @@ Message.Incoming.Msg
           { msg with payload = { msg.payload with contents } }
  | m -> Lwt.return m

type setting = { host : string; port : int }
(** NATS server connection settings. *)

(** Create TCP connection for communicate by NATS protocol. 

    @raises Connection_refused *)
let create { host; port } =
  try%lwt
    (* Create a TCP socket *)
    let socket_fd = Lwt_unix.socket PF_INET SOCK_STREAM 0 in

    (* Server details *)
    let server_address = inet_addr_of_string host in
    let server_port = port in
    let server_socket_address = ADDR_INET (server_address, server_port) in

    Lwt_unix.connect socket_fd server_socket_address;%lwt

    (* Wrap raw file descriptors into channel abstractions. *)
    let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket_fd in
    let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket_fd in

    (* The socket_fd capture is needed to close it later. *)
    Lwt.return { ic; oc; socket = socket_fd }
  with Unix.Unix_error (Unix.ECONNREFUSED, "connect", "") ->
    raise Connection_refused

let close conn =
  (* is it work? *)
  Lwt_unix.close conn.socket
