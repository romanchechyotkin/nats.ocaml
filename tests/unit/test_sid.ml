open Nats_client
open Alcotest

let test_create () =
  let sids = List.init 1000 (fun _ -> Sid.create 10) in
  let unique_sids = List.sort_uniq String.compare sids in

  check int "same length" (List.length unique_sids) (List.length sids)

let test_length () =
  for i = 0 to 10 do
    let sid = Sid.create i in
    check int "same length" (String.length sid) i
  done

let () =
  let open Alcotest in
  run "Sid tests"
    [
      ( "create",
        [
          test_case "test_uniqness" `Quick test_create;
          test_case "test_length" `Quick test_length;
        ] );
    ]
