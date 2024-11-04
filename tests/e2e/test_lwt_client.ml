open Alcotest

let default_uri = Uri.of_string "tcp://127.0.0.1:4222"

let init_test_correct_address _ () =
  let%lwt _ = Nats_client_lwt.connect default_uri in

  Lwt.return_unit

let init_test_wrong_address _ () =
  try%lwt
    let%lwt _ =
      Nats_client_lwt.connect (Uri.of_string "tcp://127.0.0.1:8000")
    in

    fail "Expected Connection_refused exception, but none was raised"
  with Nats_client_lwt.Connection.Connection_refused -> Lwt.return_unit

let connect_test _ () =
  let%lwt client = Nats_client_lwt.connect default_uri in

  Nats_client_lwt.send_initialize_message client
    { echo = true; tls_required = false; pedantic = false; verbose = true };%lwt

  Lwt.return ()

let connect_test_with_verbose_false _ () =
  let%lwt client = Nats_client_lwt.connect default_uri in

  Nats_client_lwt.send_initialize_message client
    { echo = true; tls_required = false; pedantic = false; verbose = false };%lwt

  Lwt.return ()

let () =
  let open Alcotest_lwt in
  Lwt_main.run
  @@ run "NATS Client tests"
       [
         ( "init connection",
           [
             test_case "correct address" `Quick init_test_correct_address;
             test_case "wrong address" `Quick init_test_wrong_address;
           ] );
         ( "connect",
           [
             test_case "init connection from client" `Quick connect_test;
             test_case "init connection from client with verbose false" `Quick
               connect_test_with_verbose_false;
           ] );
       ]
