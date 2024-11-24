let main =
  Lwt_switch.with_switch @@ fun switch ->
  let%lwt client =
    Nats_client_lwt.connect ~switch ~settings:[ `Echo ]
      (Uri.of_string "nats://127.0.0.1:4222")
  in

  let%lwt subscription = Nats_client_lwt.sub client ~subject:"greet.*" () in

  for%lwt i = 0 to 50 do
    Printf.sprintf "hello %d" i
    |> Nats_client_lwt.pub client ~subject:"greet.joe"
  done;%lwt

  let handle_requests (request : Nats_client.Protocol.msg) =
    Lwt_unix.sleep 1.0;%lwt
    Lwt_io.printlf "received message: %s" request.payload
  in

  Lwt.dont_wait
    (fun () ->
      Lwt_stream.iter_n ~max_concurrency:25 handle_requests
        subscription.messages)
    (function Lwt_io.Channel_closed _ -> () | e -> raise e);

  Lwt_unix.sleep 4.0;%lwt
  Lwt.return_unit

let () = Lwt_main.run main
