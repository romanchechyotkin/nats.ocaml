open Lwt.Syntax
open Client

let main () =
  let host = Client.default_host in
  let port = Client.default_port in
  let* client = Client.connect ~host ~port in

  let* () = Client.sub client ~subject:"FOO" in
  let* () = Client.sub client ~subject:"FRONT.*" in
  let* () = Client.sub client ~subject:"NOTIFY" in

  let* () =
    Client.pub client ~subject:"FOO" ~reply_to_subject:None
      ~payload:"HELLO NATS!"
  in
  let* () =
    Client.pub client ~subject:"FRONT.DOOR" ~reply_to_subject:None
      ~payload:"HELLO NATS!"
  in
  let* () =
    Client.pub client ~subject:"NOTIFY" ~reply_to_subject:None
      ~payload:"HELLO NATS!"
  in

  Client.close client

let () = Lwt_main.run (main ())
