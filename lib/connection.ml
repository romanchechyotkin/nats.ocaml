(** Abstraction over TCP connection for communicate by NATS protocol.

    Protocol {: https://docs.nats.io/reference/reference-protocols/nats-protocol }. *)

open Unix

type t = {
  ic : Lwt_io.input_channel;
  oc : Lwt_io.output_channel;
  socket : Lwt_unix.file_descr;
}
(** NATS client connection. *)

exception Connection_refused
(** Raised when failed to make a TCP connection. *)

module Send = struct
  let pong conn = Lwt_io.write conn.oc "PONG\r\n"
  let ping conn = Lwt_io.write conn.oc "PING\r\n"

  let pub ~subject ~reply_to ~payload conn =
    Lwt_io.fprintf conn.oc "PUB %s%s %d\r\n%s\r\n" subject
      (Option.fold ~none:"" ~some:(Printf.sprintf " %s") reply_to)
      (String.length payload) payload

  let sub ~subject ~queue_group ~sid conn =
    Lwt_io.fprintf conn.oc "SUB %s%s %s\r\n" subject
      (Option.fold ~none:"" ~some:(Printf.sprintf " %s") queue_group)
      sid

  let connect ~json conn =
    (* NOTE: Yojson.Safe.pp gives a bad result.
       TODO: improve performance of JSON encoding (now is bad) *)
    Lwt_io.fprintf conn.oc "CONNECT %s\r\n" (Yojson.Safe.to_string json)

  (* TODO: add other *)
end

let receive conn =
  let%lwt line = Lwt_io.read_line conn.ic in

  let is_starts prefix = String.starts_with ~prefix in

  (* TODO: improve message parsing *)
  match line with
  | "PING" -> Lwt.return Message.Incoming.Ping
  | "PONG" -> Lwt.return Message.Incoming.Pong
  | "+OK" -> Lwt.return Message.Incoming.Ok
  | "+ERR" -> Lwt.return Message.Incoming.Err
  | line when is_starts "INFO" line ->
      Scanf.sscanf line "INFO %s" (fun json ->
          Lwt.return @@ Message.Incoming.Info json)
  | line when is_starts "MSG" line -> (
      (* it's very bad code >_< *)
      let read_payload bytes =
        let%lwt payload = Lwt_io.read ~count:bytes conn.ic in
        let%lwt _ = Lwt_io.read ~count:2 conn.ic in
        Lwt.return payload
      in

      match String.split_on_char ' ' line with
      | [ _; subject; sid; bytes ] ->
          let%lwt payload = read_payload (int_of_string bytes) in
          Lwt.return
            Message.Incoming.(Msg { subject; sid; payload; reply_to = None })
      | [ _; subject; sid; reply_to; bytes ] ->
          let%lwt payload = read_payload (int_of_string bytes) in
          Lwt.return
            Message.Incoming.(
              Msg { subject; sid; payload; reply_to = Some reply_to })
      | _ -> failwith "invalid MSG message")
  | line -> failwith @@ "unknown incoming message: " ^ line

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
