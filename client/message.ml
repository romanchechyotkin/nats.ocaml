type t =
  | Ping
  | Connect of Yojson.Safe.t
  | Pub of { subject : string; reply_to : string option; payload : string }
  | Sub of { subject : string; queue_group : string option; sid : Sid.t }

module Initial = struct
  type t = {
    verbose : bool;
    pedantic : bool;
    tls_required : bool;
    echo : bool;
    lang : string;
  }

  let to_yojson t : Yojson.Safe.t =
    `Assoc
      [
        ("verbose", `Bool t.verbose);
        ("pedantic", `Bool t.pedantic);
        ("tls_required", `Bool t.tls_required);
        ("echo", `Bool t.echo);
        ("lang", `String t.lang);
      ]
end