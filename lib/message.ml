(** NATS message. *)

module Incoming = struct
  open Ppx_yojson_conv_lib.Yojson_conv

  module INFO = struct
    type t = {
      server_id : string;
      server_name : string;
      version : string;
      go : string;
      host : string;
      port : int;
      headers : bool;
      max_payload : int;
      proto : int;
      client_id : int option; [@default None] (* uint64 brr *)
      auth_required : bool; [@default false]
      tls_required : bool; [@default false]
      tls_verify : bool; [@default false]
      tls_available : bool; [@default false]
      connect_urls : string list; [@default []]
      ws_connect_urls : string list; [@default []]
      ldm : bool; [@default false]
      git_commit : string option; [@default None]
      jetstream : bool; [@default false]
      ip : string option; [@default None]
      client_ip : string option; [@default None]
      nonce : string option; [@default None]
      cluster : string option; [@default None]
      domain : string option; [@default None]
    }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  type t = INFO of INFO.t | MSG of msg | PING | PONG | OK | ERR of err

  and msg = {
    subject : string;
    sid : Sid.t;
    reply_to : string option;
    payload : payload;
  }

  and payload = { size : int; contents : string }
  and err = string

  let pp_msg fmt { subject; sid; reply_to; payload } =
    Format.fprintf fmt "MSG %s %s %s %d %s" subject sid
      (Option.value ~default:"?" reply_to)
      payload.size payload.contents

  let pp fmt = function
    | INFO info ->
        Format.fprintf fmt "INFO %s"
          (INFO.yojson_of_t info |> Yojson.Safe.to_string)
    | MSG msg -> pp_msg fmt msg
    | PING -> Format.fprintf fmt "PING"
    | PONG -> Format.fprintf fmt "PONG"
    | OK -> Format.fprintf fmt "+OK"
    | ERR e -> Format.fprintf fmt "+ERR '%s'" e

  (** Generic message line parser.
  
      {b Note}. Bad performance. *)
  module Parser = struct
    (* FIXME: lots of string copying. *)

    (** @raises Yojson.Json_error  *)
    let info_of_line line =
      (* INFO {"option_name":option_value,...}␍␊ *)
      Scanf.sscanf line "INFO %s" (fun s ->
          Yojson.Safe.from_string s |> INFO.t_of_yojson)

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

    let err_of_line line =
      (*
           -ERR 'Unknown Protocol Operation'
                ^                          ^
                6                    (len - 1 - 6)
      *)
      String.sub line 6 (String.length line - 1 - 6)

    (** @raises Invalid_argument *)
    let of_line = function
      | "PING" -> PING
      | "PONG" -> PONG
      | "+OK" -> OK
      | line when String.starts_with ~prefix:"-ERR" line ->
          ERR (err_of_line line)
      | line when String.starts_with ~prefix:"INFO" line ->
          INFO (info_of_line line)
      | line when String.starts_with ~prefix:"MSG" line ->
          MSG (msg_of_line line)
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

  let default =
    { verbose = false; pedantic = false; tls_required = false; echo = false }

  let of_poly_variants v =
    List.fold_left
      (fun m -> function
        | `Echo -> { m with echo = true }
        | `Verbose -> { m with verbose = true })
      default v
end
