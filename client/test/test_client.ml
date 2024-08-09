open Client

let main () =
  let nats_client = Client.connect "147.75.47.215" Client.default_port in
  print_endline (Client.url nats_client);

  (* Client.close nats_client *)
;;

main ()
