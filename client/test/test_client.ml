let main () =
  let%lwt client = Nats_client.make { port = 4222; host = "127.0.0.1" } in

  let%lwt resp =
    client#init
      {
        echo = true;
        tls_required = false;
        pedantic = false;
        verbose = true;
      }
  in
  Printf.printf "resp: %s\n" resp;

  client#sub ~subject:"FOO" ();%lwt
  let%lwt resp = client#receive_response in
  Printf.printf "resp: %s\n" resp;

  client#sub ~subject:"FRONT.*" ();%lwt
  let%lwt resp = client#receive_response in
  Printf.printf "resp: %s\n" resp;

  client#pub ~subject:"FOO" "HELLO NATS!";%lwt
  let%lwt resp = client#receive_response in
  Printf.printf "resp: %s\n" resp;

  client#pub ~subject:"FRONT.DOOR" ~reply_to:"FOO" "HELLO NATS!";%lwt
  let%lwt resp = client#receive_response in
  Printf.printf "resp: %s\n" resp;

  client#close;%lwt

  Lwt.return_unit

let () = Lwt_main.run @@ main ()
