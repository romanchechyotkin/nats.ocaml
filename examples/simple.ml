let () =
  Lwt_main.run @@ Lwt_switch.with_switch
  @@ fun switch ->
  (* Connect to a NATS server. *)
  let%lwt client =
    let settings = Nats_client.settings ~echo:true () in
    Nats_client_lwt.connect ~switch ~settings
      (Uri.of_string "tcp://127.0.0.1:4222")
  in

  (* Subscribe to HELLO subject. *)
  let%lwt hello_subject = Nats_client_lwt.sub client ~subject:"HELLO" () in

  (* Handle incoming HELLO subject messages. *)
  Nats_client_lwt.Subscription.handle hello_subject (fun msg ->
      Lwt_io.printf "HELLO: %s\n" msg.payload.contents);

  (* Send "Hello World" message to HELLO subject. *)
  Nats_client_lwt.pub client ~subject:"HELLO" "Hello World";%lwt

  Lwt_unix.sleep 0.1
