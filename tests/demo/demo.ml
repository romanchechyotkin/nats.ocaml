let main () =
  let%lwt client = Nats_client_lwt.make { port = 4222; host = "127.0.0.1" } in

  let%lwt resp =
    client#init
      { echo = true; tls_required = false; pedantic = false; verbose = true }
  in
  Format.printf "resp: %a\n" Yojson.Safe.pp resp;
  flush_all ();

  Nats_client_lwt.Subscription.handle client#incoming (fun msg ->
      Lwt_fmt.printf "LOG: %a\n" Nats_client.Message.Incoming.pp msg;%lwt
      Lwt_fmt.flush Lwt_fmt.stdout);

  let%lwt foo_subj = client#sub ~subject:"FOO" () in

  ( Nats_client_lwt.Subscription.handle foo_subj @@ fun msg ->
    Lwt_fmt.printf "HANDLER\n\tFOO: %a\n" Nats_client.Message.Incoming.pp_msg
      msg );

  let%lwt front_subj = client#sub ~subject:"FRONT.*" () in

  ( Nats_client_lwt.Subscription.handle front_subj @@ fun msg ->
    Lwt_fmt.printf "HANDLER\n\tFRONT.*: %a\n"
      Nats_client.Message.Incoming.pp_msg msg );

  client#pub ~subject:"FOO" "HELLO NATS!";%lwt

  client#pub ~subject:"FRONT.DOOR" "HELLO NATS!";%lwt

  Lwt_unix.sleep 1.;%lwt

  client#pub ~subject:"FRONT.1" ~reply_to:"FOO" "HELLO NATS!";%lwt
  client#pub ~subject:"FRONT.2" ~reply_to:"FOO" "HELLO NATS!";%lwt
  client#pub ~subject:"FRONT.3" ~reply_to:"FOO" "HELLO NATS!";%lwt

  client#pub ~subject:"FOO" "HELLO NATS!";%lwt

  flush_all ();
  Lwt_unix.sleep 1.;%lwt

  client#close;%lwt

  Lwt.return_unit

let () = Lwt_main.run @@ main ()
