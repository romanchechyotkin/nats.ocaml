open Client

let main () =
  let nats_client = Client.connect "147.75.47.215" Client.default_port in

  Client.pub nats_client "FOO" "HELLO NATS!";

  Client.close nats_client
;;

main ()
