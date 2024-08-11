open Client

let main () =
  let host = Client.default_host in
  let port = Client.default_port in
  let client = Client.connect host port in

  Client.sub client "FOO";
  Client.sub client "FRONT.*";
  Client.sub client "NOTIFY";

  Client.pub client "FOO" None "HELLO NATS!";
  Client.pub client "FRONT.DOOR" None "HELLO NATS!";
  Client.pub client "NOTIFY" None "HELLO NATS!";

  Client.close client

let () = main ()
