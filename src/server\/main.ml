open Lwt.Syntax
open Lwt.Infix

let conns = ref [] 

let port = 8080
let backlog = 10
let buffer_size = 1024

let handle_connection (client_sock, client_addr) =
  let client_ip =
    match client_addr with
    | Unix.ADDR_INET (addr, port) ->
        Printf.sprintf "%s:%d" (Unix.string_of_inet_addr addr) port
    | _ -> "Unknown address"
  in
  Printf.printf "Connection from %s\n%!" client_ip;
  conns := client_sock :: !conns;
  
  let buffer = Bytes.create buffer_size in

  let rec echo () =
    Lwt_unix.read client_sock buffer 0 buffer_size >>= fun bytes_read ->
    if bytes_read = 0 then Lwt.return_unit
    else Lwt_unix.write client_sock buffer 0 bytes_read >>= fun _ -> echo ()
  in

  echo () >>= fun () -> Lwt_unix.close client_sock

let create_server_socket () =
  let open Unix in
  let sock = Lwt_unix.socket PF_INET SOCK_STREAM 0 in
  let addr = ADDR_INET (inet_addr_any, port) in
  let* () = Lwt_unix.bind sock addr in
  let () = Lwt_unix.listen sock backlog in
  Lwt.return sock

let main () =
  let* server_sock = create_server_socket () in
  let rec accept_connections () =
    Lwt_unix.accept server_sock >>= handle_connection >>= accept_connections
  in
  accept_connections ()

let () = Lwt_main.run (main ())
