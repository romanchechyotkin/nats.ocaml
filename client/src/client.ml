open Lwt.Infix
open Unix
open Messages

module Client = struct
  let default_host: string = "nats://127.0.0.1"
  let default_port: int = 4222
  let lang: string = "ocaml"

  type 'a t = {
    sockaddr : sockaddr;
    socket : Lwt_unix.file_descr;
    url : string;
  }

  let handle_message file_descr =
    let buffer = Bytes.create 1024 in
    Lwt_unix.recvfrom file_descr buffer 0 1024 []
    >>= fun (num_bytes, _) ->
      print_endline "Received from server\n"; 
      let message = Bytes.sub_string buffer 0 num_bytes in
      Lwt.return message


  let send_message client message = 
    let msg: bytes = Bytes.of_string (Messages.string_of_mtype message) in 
    Lwt_unix.sendto client.socket msg 0 (String.length (Messages.string_of_mtype message)) [] client.sockaddr
    >>= fun (_) -> handle_message client.socket

  let connect host port =
    (* Create a TCP socket *)
    let socket_fd = Lwt_unix.socket PF_INET SOCK_STREAM 0 in

    (* Server details *)
    let server_address = inet_addr_of_string host in 
    let server_port = port in 
    let server_socket_address = ADDR_INET (server_address, server_port) in 

    Lwt_unix.connect socket_fd server_socket_address
    >>= fun (_) -> print_endline "connected to server";

    let client: 'a t = {
      url = Printf.sprintf "%s:%d" host port; 
      socket = socket_fd;
      sockaddr = server_socket_address;
    } in

    (* Send request *)
    send_message client CONNECT
    >>= fun (response) -> print_endline response;

    Lwt.return client

  let url client = 
    client.url;;  

  let close client =
    (* Close the socket *)
    print_endline "closed client";
    Lwt_unix.close client.socket  

end

