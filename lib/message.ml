(** NATS message. *)

module Incoming = struct
  (* TODO: make type for INFO *)
  type t = Info of string | Msg of msg | Ping | Pong | Ok | Err

  and msg = {
    subject : string;
    sid : Sid.t;
    reply_to : string option;
    payload : string;
  }

  let pp_msg fmt { subject; sid; payload; reply_to } =
    Format.fprintf fmt "MSG %s %s %s %s" subject sid
      (Option.value ~default:"?" reply_to)
      payload

  let pp fmt = function
    | Info json -> Format.fprintf fmt "INFO %s" json
    | Msg msg -> pp_msg fmt msg
    | Ping -> Format.fprintf fmt "PING"
    | Pong -> Format.fprintf fmt "PONG"
    | Ok -> Format.fprintf fmt "+OK"
    | Err -> Format.fprintf fmt "+ERR"
end

(** Initial message. *)
module Initial = struct
  type t = { verbose : bool; pedantic : bool; tls_required : bool; echo : bool }
  (** Protocol. https://docs.nats.io/reference/reference-protocols/nats-protocol#syntax-1 *)

  (* TODO: for encoding/decoding JSON should use [ppx_deriving_yojson] preprocessor. *)
  let to_yojson t : Yojson.Safe.t =
    `Assoc
      [
        ("verbose", `Bool t.verbose);
        ("pedantic", `Bool t.pedantic);
        ("tls_required", `Bool t.tls_required);
        ("echo", `Bool t.echo);
        ("lang", `String "ocaml");
      ]
end
