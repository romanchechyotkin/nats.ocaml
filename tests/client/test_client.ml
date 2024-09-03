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
      let _ = fail "Expected Connection_refused exception, but none was raised" in
      Lwt.return_unit)
    (function
      | Connection.Connection_refused -> Lwt.return_unit
      | exn ->
          Alcotest.fail
            (Printf.sprintf "Unexpected exception: %s" (Printexc.to_string exn)))

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
       ]
