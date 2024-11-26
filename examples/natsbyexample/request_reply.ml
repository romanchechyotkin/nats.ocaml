let main =
  Lwt_switch.with_switch @@ fun switch ->
  let%lwt client =
    Nats_client_lwt.connect ~switch ~settings:[ `Echo ]
      (Uri.of_string "nats://127.0.0.1:4222")
  in

  let%lwt subscription = Nats_client_lwt.sub client ~subject:"greet.*" () in

  Nats_client_lwt.Subscription.handle subscription (fun request ->
      match request.reply_to with
      | None -> Lwt.return_unit
      | Some reply ->
          Printf.sprintf "hello, %s"
            String.(sub request.subject 6 (length request.subject - 6))
          |> Nats_client_lwt.pub client ~subject:reply);

  let%lwt response = Nats_client_lwt.request client ~subject:"greet.sue" "" in
  Lwt_io.printlf "response: %s;" response;%lwt

  let%lwt response = Nats_client_lwt.request client ~subject:"greet.john" "" in
  Lwt_io.printlf "response: %s;" response;%lwt

  let%lwt response =
    Lwt_unix.with_timeout 1. @@ fun () ->
    Nats_client_lwt.request client ~subject:"greet.bob" ""
  in

  Lwt_io.printlf "response: %s;" response;%lwt

  Lwt.return_unit

let () = Lwt_main.run main
