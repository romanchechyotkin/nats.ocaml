let () =
  Lwt_main.run
  @@
  (* Make connection with NATS server. *)
  let%lwt client = Nats_client_lwt.make { port = 4222; host = "127.0.0.1" } in

  (* Initialize connection with parameters. Required. *)
  client#init
    { echo = true; tls_required = false; pedantic = false; verbose = false };%lwt

  (* Subscribe to HELLO subject. *)
  let%lwt hello_subject = client#sub ~subject:"HELLO" () in

  (* Handle incoming HELLO subject messages. *)
  Nats_client_lwt.Subscription.handle hello_subject (fun msg ->
      Lwt_io.printf "HELLO: %s\n" msg.payload.contents);

  (* Send "Hello World" message to HELLO subject. *)
  client#pub ~subject:"HELLO" "Hello World";%lwt

  Lwt_unix.sleep 0.1;%lwt
  client#close
