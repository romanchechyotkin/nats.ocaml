(** NATS message. *)

module Incoming = struct
  (* TODO: make type for INFO *)
  type t = Info of Yojson.Safe.t | Msg of msg | Ping | Pong | OK | ERR

  and msg = {
    subject : string;
    sid : Sid.t;
    reply_to : string option;
    payload : payload;
  }

  and payload = { size : int; contents : string }

  let pp_msg fmt { subject; sid; reply_to; payload } =
    Format.fprintf fmt "MSG %s %s %s %d %s" subject sid
      (Option.value ~default:"?" reply_to)
      payload.size payload.contents

  let pp fmt = function
    | Info json -> Format.fprintf fmt "INFO %a" Yojson.Safe.pp json
    | Msg msg -> pp_msg fmt msg
    | Ping -> Format.fprintf fmt "PING"
    | Pong -> Format.fprintf fmt "PONG"
    | OK -> Format.fprintf fmt "+OK"
    | ERR -> Format.fprintf fmt "+ERR"

  (** Generic message line parser.
  
      {b Note}. Bad performance. *)
  module Parser = struct
    (* FIXME: lots of string copying. *)

    (** @raises Yojson.Json_error  *)
    let info_of_line line =
      (* INFO {"option_name":option_value,...}␍␊ *)
      Scanf.sscanf line "INFO %s" (fun s -> Yojson.Safe.from_string s)

    let msg_of_line line =
      (* MSG <subject> <sid> [reply-to] <#bytes>␍␊[payload]␍␊ *)
      (* DRY? *)
      match String.split_on_char ' ' line with
      | [ "MSG"; subject; sid; size ] ->
          {
            subject;
            sid;
            payload = { size = int_of_string size; contents = "" };
            reply_to = None;
          }
      | [ "MSG"; subject; sid; reply_to; size ] ->
          {
            subject;
            sid;
            payload = { size = int_of_string size; contents = "" };
            reply_to = Some reply_to;
          }
      | _ -> raise (Invalid_argument "msg line")

    (** @raises Invalid_argument
        @raises Invalid_argument Yojson.Json_error *)
    let of_line = function
      | "PING" -> Ping
      | "PONG" -> Pong
      | "+OK" -> OK
      | "+ERR" -> ERR
      | line when String.starts_with ~prefix:"INFO" line ->
          Info (info_of_line line)
      | line when String.starts_with ~prefix:"MSG" line ->
          Msg (msg_of_line line)
      | _ -> raise (Invalid_argument "incoming message line")
  end
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
