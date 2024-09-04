open Nats_client
open Alcotest

let init_test_correct_address _ () =
  Lwt.catch
    (fun () ->
      let%lwt _client = Nats_client.make { port = 4222; host = "127.0.0.1" } in
      Lwt.return_unit)
    (function
      | Connection.Connection_refused -> Lwt.return_unit
      | exn ->
          Alcotest.fail
            (Printf.sprintf "Unexpected exception: %s" (Printexc.to_string exn)))

let init_test_wrong_address _ () =
  Lwt.catch
    (fun () ->
      let%lwt _client = Nats_client.make { port = 42222; host = "127.0.0.1" } in
      let _ =
        fail "Expected Connection_refused exception, but none was raised"
      in
      Lwt.return_unit)
    (function
      | Connection.Connection_refused -> Lwt.return_unit
      | exn ->
          Alcotest.fail
            (Printf.sprintf "Unexpected exception: %s" (Printexc.to_string exn)))

let connect_test _ () =
  let%lwt client = Nats_client.make { port = 4222; host = "127.0.0.1" } in
  let%lwt resp =
    client#init
      { echo = true; tls_required = false; pedantic = false; verbose = true }
  in
  check string "Expected +OK response" "+OK" resp;
  Lwt.return ()

let connect_test_with_verbose_false _ () =
  let%lwt client = Nats_client.make { port = 4222; host = "127.0.0.1" } in
  let%lwt resp =
    client#init
      { echo = true; tls_required = false; pedantic = false; verbose = false }
  in

  if resp == "+OK" then fail "got +OK response";

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
