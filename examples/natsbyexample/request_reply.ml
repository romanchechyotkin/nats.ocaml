let main =
  Lwt_switch.with_switch @@ fun switch ->
  let%lwt client =
    Nats_client_lwt.connect ~switch ~settings:[ `Echo ]
      (Uri.of_string "nats://127.0.0.1:4222")
  in

  let%lwt requests = Nats_client_lwt.sub client ~subject:"greet.*" () in

  Nats_client_lwt.Subscription.handle requests (fun request ->
      match request.reply_to with
      | None -> Lwt.return_unit
      | Some reply ->
          Printf.sprintf "hello, %s" request.subject
          |> Nats_client_lwt.pub client ~subject:reply);

  Lwt.return_unit

let () = Lwt_main.run main
