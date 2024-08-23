open Lwt

let main () =
  let%lwt client = Nats_client.make { port = 4222; host = "127.0.0.1" } in

  let%lwt resp =
    client#init
      { echo = true; tls_required = false; pedantic = false; verbose = true }
  in
  Printf.printf "resp: %s\n" resp;

  let receive_message () =
    client#receive
    >|= Format.printf "resp: %a\n" Nats_client.Message.Incoming.pp
  in

  client#sub ~subject:"FOO" ();%lwt
  receive_message ();%lwt

  client#sub ~subject:"FRONT.*" ();%lwt
  receive_message ();%lwt

  client#pub ~subject:"FOO" "HELLO NATS!";%lwt
  receive_message ();%lwt
  receive_message ();%lwt

  client#pub ~subject:"FRONT.DOOR" ~reply_to:"FOO" "HELLO NATS!";%lwt
  receive_message ();%lwt
  receive_message ();%lwt
  receive_message ();%lwt
  receive_message ();%lwt

  client#close;%lwt

  Lwt.return_unit

let () = Lwt_main.run @@ main ()
