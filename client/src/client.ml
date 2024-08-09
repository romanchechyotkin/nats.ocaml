open Lwt.Infix
open Unix
open Messages

module Client = struct
  let default_host : string = "nats://127.0.0.1"
  let default_port : int = 4222
  let lang : string = "ocaml"
  let crlf : string = "\r\n"

  type 'a t = {
    sockaddr : sockaddr;
    socket : Lwt_unix.file_descr;
  }

  let handle_message file_descr =
    let buffer = Bytes.create 1024 in
    Lwt_unix.recvfrom file_descr buffer 0 1024 [] >>= fun (num_bytes, _) ->
    let message = Bytes.sub_string buffer 0 num_bytes in
    Lwt.return message

  let send_message client mtype message =
    let message =
      match mtype with
      | Messages.CONNECT ->
          Printf.sprintf "%s %s%s" (Messages.string_of_mtype mtype) message crlf
      | Messages.PUB -> Printf.sprintf "%s %s" (Messages.string_of_mtype mtype) message
      | _ -> ""
    in
    print_endline ("sending request: " ^ message);
    let msg : bytes = Bytes.of_string message in
    let l = String.length message in
    Lwt_unix.sendto client.socket msg 0 l []
      client.sockaddr
    >>= fun _ -> 
      handle_message client.socket

  let init_connect (client : 'a t) =
    let connect_msg =
      Yojson.Raw.to_string
        (`Assoc
          [
            (* ("verbose", `Bool true); *)
            (* ("pedantic", `Bool false); *)
            (* ("tls_required", `Bool false); *)
            (* ("lang", `Stringlit lang); *)
            (* ("echo", `Bool true); *)
          ])
    in
    send_message client CONNECT connect_msg >>= fun response ->
    Lwt.return response

  let connect host port =
    let client =
      Lwt_main.run
        ((* Create a TCP socket *)
         let socket_fd = Lwt_unix.socket PF_INET SOCK_STREAM 0 in

         (* Server details *)
         let server_address = inet_addr_of_string host in
         let server_port = port in
         let server_socket_address = ADDR_INET (server_address, server_port) in

         Lwt_unix.connect socket_fd server_socket_address >>= fun _ ->
         print_endline "connected to server";
         handle_message socket_fd >>= fun msg ->
         print_endline msg;

         let client : 'a t =
           {
             socket = socket_fd;
             sockaddr = server_socket_address;
           }
         in

         (* Send CONNECT request *)
         init_connect client >>= fun response ->
         print_endline response;

         Lwt.return client)
    in
    client


  let pub client subject payload = 
      let msg = Printf.sprintf "%s %d%s%s%s" subject (Bytes.length (Bytes.of_string payload)) crlf payload crlf in 
      Lwt_main.run (
        send_message client Messages.PUB msg >>= fun response -> print_endline response;
        Lwt.return_unit
      )

  let close client =
    (* Close the socket *)
    print_endline "closed client";
    Lwt_unix.close client.socket
end
