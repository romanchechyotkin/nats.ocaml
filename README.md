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
  let host = Client.default_host in
  let port = Client.default_port in
  let* client = Client.connect host port in (* client initialization *)

  (* subscription to subject *)
  let* () = Client.sub client "FOO" in
  let* () = Client.sub client "FRONT.*" in
  let* () = Client.sub client "NOTIFY" in

  (* publishing message to subject *)
  let* () = Client.pub client "FOO" None "HELLO NATS!" in
  let* () = Client.pub client "FRONT.DOOR" None "HELLO NATS!" in
  let* () = Client.pub client "NOTIFY" None "HELLO NATS!" in

  (* closing connection to NATS server *)  
  Client.close client

let () = Lwt_main.run (main ())
```