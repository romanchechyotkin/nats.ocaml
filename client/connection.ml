open Unix

type t = {
  ic : Lwt_io.input_channel;
  oc : Lwt_io.output_channel;
  socket : Lwt_unix.file_descr;
}

let crlf = "\r\n"

let send_message conn message =
  let open Message in
  match message with
  | Connect json ->
      (* NOTE: Yojson.Safe.pp gives a bad result.
         TODO: improve performance of JSON encoding (now is bad) *)
      Lwt_io.fprintf conn.oc "CONNECT %s\r\n" (Yojson.Safe.to_string json)
  | Pub { subject; reply_to; payload } ->
      Lwt_io.fprintf conn.oc "PUB %s%s %d\r\n%s\r\n" subject
        (Option.fold ~none:"" ~some:(Printf.sprintf " %s") reply_to)
        (String.length payload) payload
  | Sub { subject; queue_group; sid } ->
      Lwt_io.fprintf conn.oc "SUB %s%s %s\r\n" subject
        (Option.fold ~none:"" ~some:(Printf.sprintf " %s") queue_group)
        sid
  | _ -> failwith "unknown message type"

let recv_response conn = Lwt_io.read_line conn.ic

let create ({ host; port } : Settings.t) =
  (* Create a TCP socket *)
  let socket_fd = Lwt_unix.socket PF_INET SOCK_STREAM 0 in

  (* Server details *)
  let server_address = inet_addr_of_string host in
  let server_port = port in
  let server_socket_address = ADDR_INET (server_address, server_port) in

  Lwt_unix.connect socket_fd server_socket_address;%lwt

  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket_fd in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket_fd in

  Lwt.return { ic; oc; socket = socket_fd }

let close conn =
  (* is it work? *)
  Lwt_unix.close conn.socket
