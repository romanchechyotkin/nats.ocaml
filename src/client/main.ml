open Lwt.Infix
open Lwt.Syntax

let server_ip = "127.0.0.1"
let server_port = 8080
let buffer_size = 1024

let connect_to_server ip port =
  let inet_addr = Unix.inet_addr_of_string ip in
  let sockaddr = Unix.ADDR_INET (inet_addr, port) in
  let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Lwt_unix.connect socket sockaddr >|= fun () -> socket

let send_message socket message =
  let msg_bytes = Bytes.of_string message in
  let msg_length = Bytes.length msg_bytes in
  Lwt_unix.write socket msg_bytes 0 msg_length

  let rec receive_messages socket =
    let buffer = Bytes.create buffer_size in
    Lwt_unix.read socket buffer 0 buffer_size >>= fun bytes_read ->
    
    if bytes_read = 0 then
      Lwt.return_unit
    else
      let message = Bytes.sub_string buffer 0 bytes_read in
      Printf.printf "Received from server: %s\n%!" message;
      receive_messages socket

let main () =
  let* socket = connect_to_server server_ip server_port in
  let* _ = send_message socket "Hello, server!" in
  receive_messages socket

let () = Lwt_main.run (main ())
