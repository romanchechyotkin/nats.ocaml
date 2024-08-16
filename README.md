# NATS - OCaml Client

[OCaml](https://ocaml.org/) client for the [NATS messaging system](https://nats.io).

[![License Apache 2][License-Image]][License-Url]

[License-Url]: https://www.apache.org/licenses/LICENSE-2.0
[License-Image]: https://img.shields.io/badge/License-Apache2-blue.svg

## CONTRIBUTING

`nats_ocaml` is an open-source project and contributions are very welcome! Let's make a greate ecosystem together! Please make sure to read [contributing guide](/CONTRIBUTING.md)

## USAGE 
```ocaml
open Client
open Lwt.Syntax

let main () =
  (* client initialization *)
  let* client = Client.connect ~host:"127.0.0.1" () in
  (* or  
  let* client = Client.connect () in  
  *)
  
  (* subscription to subject *)
  let* () = Client.sub client ~subject:"FOO" in
  let* () = Client.sub client ~subject:"FRONT.*" in
  let* () = Client.sub client ~subject:"NOTIFY" in

  (* publishing message to subject *)
  let* () = Client.pub client ~subject:"FOO" ~payload:"HELLO NATS!" () in
  let* () =
    Client.pub client ~subject:"FRONT.DOOR" ~reply_to_subject:"FOO"
      ~payload:"HELLO NATS!" ()
  in
  let* () = Client.pub client ~subject:"NOTIFY" ~payload:"HELLO NATS!" () in

  (* closing connection to NATS server *)  
  Client.close client

let () = Lwt_main.run (main ())
```

## SOURCES
[NATS documentation](https://docs.nats.io/)

[NATS Client protocol documentation](https://docs.nats.io/reference/reference-protocols/nats-protocol)