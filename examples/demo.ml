let main () =
  Lwt_switch.with_switch @@ fun switch ->
  let%lwt client =
    let settings = Nats_client.settings ~echo:true () in
    Nats_client_lwt.connect ~switch ~settings
      (Uri.of_string "tcp://127.0.0.1:4222")
  in

  Format.printf "info %a\n" Yojson.Safe.pp client.info;

  Nats_client_lwt.Subscription.handle client.incoming_messages (fun msg ->
      Lwt_fmt.printf "LOG: %a\n" Nats_client.Incoming_message.pp msg;%lwt
      Lwt_fmt.flush Lwt_fmt.stdout);

  let%lwt foo_subj = Nats_client_lwt.sub client ~subject:"FOO" () in

  ( Nats_client_lwt.Subscription.handle foo_subj @@ fun msg ->
    Lwt_fmt.printf "HANDLER\n\tFOO: %a\n" Nats_client.Incoming_message.pp_msg
      msg );

  let%lwt front_subj = Nats_client_lwt.sub client ~subject:"FRONT.*" () in

  ( Nats_client_lwt.Subscription.handle front_subj @@ fun msg ->
    Lwt_fmt.printf "HANDLER\n\tFRONT.*: %a\n"
      Nats_client.Incoming_message.pp_msg msg );

  Nats_client_lwt.pub client ~subject:"FOO" "HELLO NATS!";%lwt

  Nats_client_lwt.pub client ~subject:"FRONT.DOOR" "HELLO NATS!";%lwt

  Lwt_unix.sleep 1.;%lwt

  Nats_client_lwt.pub client ~subject:"FRONT.1" ~reply_to:"FOO" "HELLO NATS!";%lwt
  Nats_client_lwt.pub client ~subject:"FRONT.2" ~reply_to:"FOO" "HELLO NATS!";%lwt
  Nats_client_lwt.pub client ~subject:"FRONT.3" ~reply_to:"FOO" "HELLO NATS!";%lwt

  Nats_client_lwt.pub client ~subject:"FOO" "HELLO NATS!";%lwt

  flush_all ();
  Lwt_unix.sleep 1.

let () = Lwt_main.run @@ main ()
