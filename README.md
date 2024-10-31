# NATS - OCaml Client

[OCaml](https://ocaml.org/) client for the [NATS messaging system](https://nats.io).

[![License Apache 2][License-Image]][License-Url]

[License-Url]: https://www.apache.org/licenses/LICENSE-2.0
[License-Image]: https://img.shields.io/badge/License-Apache2-blue.svg

> [!WARNING]
> In active development!

## Usage

### Installation 

Currently only a development version is available. You can [pin][opam-pin]
it using the [OPAM] package manager. 
```console
$ opam nats-client-lwt.pin https://github.com/romanchechyotkin/nats.ocaml.git
```

### Simple echo example 

This example shows how to publish to a subject and handle its messages. 
Take it from [`examples/simple.ml`](./examples/simple.ml).

```ocaml
let () =
  Lwt_main.run @@

  (* Connect to a NATS server. *)
  Nats_client_lwt.with_connect_to ~port:4222 ~host:"127.0.0.1"
       ~init:
         {
           echo = true;
           tls_required = false;
           pedantic = false;
           verbose = false;
         }
  @@ fun client ->

  (* Subscribe to HELLO subject. *)
  let%lwt hello_subject = client#sub ~subject:"HELLO" () in

  (* Handle incoming HELLO subject messages. *)
  Nats_client_lwt.Subscription.handle hello_subject (fun msg ->
      Lwt_io.printf "HELLO: %s\n" msg.payload.contents);

  (* Send "Hello World" message to HELLO subject. *)
  client#pub ~subject:"HELLO" "Hello World";%lwt

  Lwt_unix.sleep 0.1
```

```console
$ docker start -a nats-server
$ dune exec ./examples/simple.exe
```

## References

- [NATS documentation](https://docs.nats.io/)
- [NATS Client protocol documentation](https://docs.nats.io/reference/reference-protocols/nats-protocol)

## Contributing

The is an open source project under the [Apache 2.0 license](./LICENSE). 
Contributions are very welcome! Let's build a great ecosystem together! 
Please be sure to read the [CONTRIBUTING.md](./CONTRIBUTING.md) before your first commit.

[OPAM]: https://opam.ocaml.org/
[opam-pin]: https://opam.ocaml.org/doc/Usage.html#opam-pin