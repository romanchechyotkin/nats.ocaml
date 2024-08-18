open Client
open Lwt.Syntax

let main () =
  let* client = Client.connect ~host:"127.0.0.1" () in

  let* () = Client.sub client ~subject:"FOO" in
  let* () = Client.sub client ~subject:"FRONT.*" in
  let* () = Client.sub client ~subject:"NOTIFY" in

  let* () = Client.pub client ~subject:"FOO" ~payload:"HELLO NATS!" () in
  let* () =
    Client.pub client ~subject:"FRONT.DOOR" ~reply_to_subject:"FOO"
      ~payload:"HELLO NATS!" ()
  in
  let* () = Client.pub client ~subject:"NOTIFY" ~payload:"HELLO NATS!" () in

  Client.close client

let () = Lwt_main.run (main ())
