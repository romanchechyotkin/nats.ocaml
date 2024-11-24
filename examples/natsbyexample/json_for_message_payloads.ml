open Lwt.Infix

let main =
  Lwt_switch.with_switch @@ fun switch ->
  let%lwt client =
    Nats_client_lwt.connect ~switch ~settings:[ `Echo ]
      (Uri.of_string "nats://127.0.0.1:4222")
  in

  let%lwt subscription = Nats_client_lwt.sub client ~subject:"foo" () in

  Nats_client_lwt.pub client ~subject:"foo"
  @@ Yojson.Safe.to_string
  @@ `Assoc [ ("foo", `String "bar"); ("bar", `Int 27) ];%lwt

  Nats_client_lwt.pub client ~subject:"foo" "not json";%lwt

  Lwt_stream.nget 2 subscription.messages
  >>= Lwt_list.iter_s (fun (request : Nats_client.Protocol.msg) ->
          let payload = request.payload in
          match Yojson.Safe.from_string payload with
          | `Assoc [ ("foo", `String foo); ("bar", `Int bar) ] ->
              Lwt_io.printlf "received valid JSON payload: foo=%s bar=%d" foo
                bar
          | _ | (exception Yojson.Json_error _) ->
              Lwt_io.printlf "received invalid JSON payload: %s" payload);%lwt

  Lwt.return_unit

let () = Lwt_main.run main
