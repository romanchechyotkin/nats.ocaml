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
