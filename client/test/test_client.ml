open Client

let main () =
  let nats_client = Client.connect Client.default_host Client.default_port in

  Client.pub nats_client "FOO" None "HELLO NATS! withopuy reply";
  Client.pub nats_client "FRONT.DOOR" (Some "JOKE.22") "Knock Knock";
  Client.pub nats_client "NOTIFY " None "";

  Client.close nats_client
;;

main ()
