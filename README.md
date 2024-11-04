# NATS - OCaml Client

[OCaml](https://ocaml.org/) client for the [NATS messaging system](https://nats.io).

[![License Apache 2][License-Image]][License-Url]

[License-Url]: https://www.apache.org/licenses/LICENSE-2.0
[License-Image]: https://img.shields.io/badge/License-Apache2-blue.svg

> [!WARNING]
> In active development! You can view the progress [here](https://github.com/users/romanchechyotkin/projects/1).

## Usage

### Installation 

Currently only a development version is available. You can [pin][opam-pin]
it using the [OPAM] package manager. 
```console
$ opam pin nats-client-lwt.dev https://github.com/romanchechyotkin/nats.ocaml.git
```

### Publish-Subscribe example 

This example shows how to publish to a subject and handle its messages. 

```ocaml
open Lwt.Infix

let main =
  (* Create a switch for automatic dispose resources. *)
  Lwt_switch.with_switch @@ fun switch ->
  
  (* Connect to a NATS server by address 127.0.0.1:4222 with ECHO flag. *)
  let%lwt client =
    Nats_client_lwt.connect ~switch ~settings:[ `Echo ]
      (Uri.of_string "nats://127.0.0.1:4222")
  in

  (* Publish 'hello' message to greet.joe subject. *)
  Nats_client_lwt.pub client ~subject:"greet.joe" "hello";%lwt

  (* Subscribe to greet.* subject. *)
  let%lwt subscription =
    Nats_client_lwt.sub ~switch client ~subject:"greet.*" ()
  in

  (* Publishes 'hello' message to three subjects. *)
  Lwt_list.iter_p
    (fun subject -> Nats_client_lwt.pub client ~subject "hello")
    [ "greet.sue"; "greet.bob"; "greet.pam" ];%lwt

  (* Handle first three incoming messages to the greet.* subject. *)
  Lwt_stream.nget 3 subscription.messages
  >>= Lwt_list.iter_s (fun (message : Nats_client.Incoming_message.msg) ->
          Lwt_io.printlf "'%s' received on %s" message.payload.contents
            message.subject)

let () = Lwt_main.run main
```

Take it from [`examples/natsbyexample/publish_subscribe.ml`](./examples/natsbyexample/publish_subscribe.ml).

```console
$ docker start -a nats-server
$ dune exec ./examples/natsbyexample/publish_subscribe.exe
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