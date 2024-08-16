open Lwt.Syntax
open Client

let main () =
  let host = Client.default_host in
  let port = Client.default_port in
  let* client = Client.connect host port in

  let* () = Client.sub client "FOO" in
  let* () = Client.sub client "FRONT.*" in
  let* () = Client.sub client "NOTIFY" in

  let* () = Client.pub client "FOO" None "HELLO NATS!" in
  let* () = Client.pub client "FRONT.DOOR" None "HELLO NATS!" in
  let* () = Client.pub client "NOTIFY" None "HELLO NATS!" in

  Client.close client

let () = Lwt_main.run (main ())
