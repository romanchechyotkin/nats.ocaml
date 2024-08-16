open Lwt.Syntax
open Lwt.Infix
open Unix
open Messages

module Client = struct
  let default_host : string = "127.0.0.1"
  let default_port : int = 4222
  let lang : string = "ocaml"
  let crlf : string = "\r\n"
  let a = ref 1

  type 'a t = { sockaddr : sockaddr; socket : Lwt_unix.file_descr }

  let handle_reply file_descr =
    let buffer = Bytes.create 1024 in
    let* num_bytes = Lwt_unix.recv file_descr buffer 0 1024 [] in
    let message = Bytes.sub_string buffer 0 num_bytes in
    Lwt.return message

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
    handle_reply client.socket

  let init_connect (client : 'a t) =
    let connect_msg =
      Yojson.Raw.to_string
        (`Assoc
          [
            ("verbose", `Bool true);
            ("pedantic", `Bool false);
            ("tls_required", `Bool false);
            ("echo", `Bool false);
            (* ("lang", `Stringlit lang); *)
          ])
    in
    send_message client CONNECT (Printf.sprintf "%s%s" connect_msg crlf)
    >|= fun response -> print_endline response

  let connect ?(host = default_host) ?(port = default_port) () =
    (* Create a TCP socket *)
    let socket_fd = Lwt_unix.socket PF_INET SOCK_STREAM 0 in

    (* Server details *)
    let server_address = inet_addr_of_string host in
    let server_port = port in
    let server_socket_address = ADDR_INET (server_address, server_port) in

    Lwt_unix.connect socket_fd server_socket_address >>= fun () ->
    let client = { sockaddr = server_socket_address; socket = socket_fd } in
    init_connect client >>= fun () -> Lwt.return client

  let pub client ~subject ?(reply_to_subject = None) ~payload () =
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
    send_message client Messages.PUB msg >|= fun response ->
    print_endline response

  let sub client ~subject =
    a := !a + 1;
    let msg = Printf.sprintf "%s %d%s" subject !a crlf in
    send_message client Messages.SUB msg >|= fun response ->
    print_endline response

  let close client =
    (* Close the socket *)
    print_endline "socket closed";
    Lwt_unix.close client.socket
end
