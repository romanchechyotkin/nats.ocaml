open Alcotest

let test_parse_err_message () =
  let message_line = "-ERR 'Unknown Protocol Operation'" in
  check string "equal"
    (Nats_client.Message.Incoming.Parser.err_of_line message_line)
    "Unknown Protocol Operation"

let () =
  run "Message parser tests"
    [
      ( "message parser",
        [ test_case "err_of_line" `Quick test_parse_err_message ] );
    ]
