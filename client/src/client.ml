open Messages
open Random
open Lwt.Syntax
open Unix

module Client = struct
  let default_host : string = "127.0.0.1"
  let default_port : int = 4222
  let lang : string = "ocaml"
  let crlf : string = "\r\n"

  type 'a t = { sockaddr : sockaddr; socket : Lwt_unix.file_descr }

  let handle_response client =
    let buffer = Bytes.create 1024 in
    let* num_bytes = Lwt_unix.recv client.socket buffer 0 1024 [] in
    if num_bytes > 0 then (
      let message = Bytes.sub_string buffer 0 num_bytes in
      print_endline ("GOT RESPONSE: " ^ message);
      Lwt.return_unit)
    else Lwt.return ()

  let send_message client mtype message =
    let message =
      match mtype with
      | CONNECT | PUB | SUB ->
          Printf.sprintf "%s %s" (mtype_to_string mtype) message
      | _ -> Printf.sprintf "%s%s" (mtype_to_string mtype) crlf
    in
    print_endline ("sending request: " ^ message);
    let msg : bytes = Bytes.of_string message in
    let l = String.length message in
    let* _ = Lwt_unix.sendto client.socket msg 0 l [] client.sockaddr in
    Lwt.return ()

  let init_connect (client : 'a t) =
    let connect_msg =
      Yojson.Raw.to_string
        (`Assoc
          [
            ("verbose", `Bool true);
            ("pedantic", `Bool false);
            ("tls_required", `Bool false);
            ("echo", `Bool true);
            (* ("lang", `Stringlit lang); *)
          ])
    in
    let* () =
      send_message client CONNECT (Printf.sprintf "%s%s" connect_msg crlf)
    in
    Lwt.return ()

  let connect ?(host = default_host) ?(port = default_port) () =
    (* Create a TCP socket *)
    let socket_fd = Lwt_unix.socket PF_INET SOCK_STREAM 0 in

    (* Server details *)
    let server_address = inet_addr_of_string host in
    let server_port = port in
    let server_socket_address = ADDR_INET (server_address, server_port) in

    let* () = Lwt_unix.connect socket_fd server_socket_address in
    let client = { sockaddr = server_socket_address; socket = socket_fd } in

    let* () = init_connect client in
    Lwt.return client

  let pub client ~subject ?reply_to_subject ~payload () =
    let msg =
      match reply_to_subject with
      | Some reply_to ->
          Printf.sprintf "%s %s %d%s%s%s" subject reply_to
            (Bytes.length (Bytes.of_string payload))
            crlf payload crlf
      | None ->
          Printf.sprintf "%s %d%s%s%s" subject
            (Bytes.length (Bytes.of_string payload))
            crlf payload crlf
    in
    let* () = send_message client Messages.PUB msg in
    let* () = handle_response client in
    Lwt.return ()

  let sub client ~subject =
    let sid = unique_sid () in
    let msg = Printf.sprintf "%s %s%s" subject sid crlf in
    let* () = send_message client Messages.SUB msg in
    let* () = handle_response client in
    Lwt.return ()

  let close client =
    (* Close the socket *)
    print_endline "socket closed";
    Lwt_unix.close client.socket
end
