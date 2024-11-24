open Ppx_yojson_conv_lib.Yojson_conv
(** NATS message. *)

(** INFO message. *)
module Information_message = struct
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
  [@@deriving yojson, show] [@@yojson.allow_extra_fields]

  let of_string line =
    (* INFO {"option_name":option_value,...}␍␊ *)
    Scanf.sscanf line "INFO %s" (fun s ->
        Yojson.Safe.from_string s |> t_of_yojson)
end

(* MSG message. *)
module Message = struct
  type t = {
    subject : string;
    sid : Sid.t;
    reply_to : string option;
    payload : string;
  }
  [@@deriving show]

  and incomplete = string -> t

  let of_string line : int * incomplete =
    (* MSG <subject> <sid> [reply-to] <#bytes>␍␊[payload]␍␊ *)
    match String.split_on_char ' ' line with
    | [ "MSG"; subject; sid; size ] ->
        ( int_of_string size,
          fun payload -> { subject; sid; payload; reply_to = None } )
    | [ "MSG"; subject; sid; reply_to; size ] ->
        ( int_of_string size,
          fun payload -> { subject; sid; payload; reply_to = Some reply_to } )
    | _ -> raise @@ Invalid_argument "invalid MSG message"
end

module Ping = struct
  type t = [ `PING ] [@@deriving show]

  let of_string : string -> t = function
    | "PING" -> `PING
    | _ -> raise @@ Invalid_argument "invalid PING message"
end

module Pong = struct
  type t = [ `PONG ] [@@deriving show]

  let of_string : string -> t = function
    | "PONG" -> `PONG
    | _ -> raise @@ Invalid_argument "invalid PONG message"
end

module Ok_or_err = struct
  type t = [ `OK | `ERR of err ] [@@deriving show]
  and err = string

  let err_of_string line =
    (*
      -ERR 'Unknown Protocol Operation'
           ^                          ^
           6                    (len - 1 - 6)
    *)
    String.sub line 6 (String.length line - 1 - 6)

  let of_string : string -> t = function
    | "+OK" -> `OK
    | line when String.starts_with ~prefix:"-ERR" line ->
        `ERR (err_of_string line)
    | _ -> raise @@ Invalid_argument "invalid +OK/-ERR message"
end

(** CONNECT message. *)
module Connection_message = struct
  type t = {
    verbose : bool; [@default false]
    pedantic : bool; [@default false]
    tls_required : bool; [@default false]
    auth_token : string option; [@default None]
    user : string option; [@default None]
    pass : string option; [@default None]
    name : string option; [@default None]
    lang : string; [@default "ocaml"]
    version : string; [@default "0.2"]
    protocol : int; [@default 0]
    echo : bool; [@default false]
    sig' : string option; [@default None] [@key "sig"]
    jwt : string option; [@default None]
    no_responders : bool; [@default false]
    headers : bool; [@default false]
    nkey : string option; [@default None]
  }
  [@@deriving yojson_of, make, show] [@@yojson.allow_extra_fields]
  (** Protocol. https://docs.nats.io/reference/reference-protocols/nats-protocol#syntax-1 *)

  let of_poly_variants v =
    List.fold_left
      (fun m -> function
        | `Echo -> { m with echo = true }
        | `Pedantic -> { m with pedantic = true }
        | `Tls_required -> failwith "nats.ocaml now now supports TLS"
        | `Auth_token token -> { m with auth_token = Some token }
        | `User user -> { m with user = Some user }
        | `Pass pass -> { m with pass = Some pass }
        | `Protocol n -> { m with protocol = n }
        | `Jwt jwt -> { m with jwt = Some jwt }
        | `Sig sig' -> { m with sig' = Some sig' }
        | `Verbose -> { m with verbose = true })
      (make ()) v
end

(* Aliases *)

type info = Information_message.t
and msg = Message.t
and ping = Ping.t
and pong = Pong.t
and ok_or_err = Ok_or_err.t
and connect = Connection_message.t [@@deriving show]

type incomplete_message =
  [ ping | pong | ok_or_err | `INFO of info | `MSG of int * Message.incomplete ]

type message =
  [ ping
  | pong
  | ok_or_err
  | `INFO of Information_message.t
  | `MSG of Message.t ]
[@@deriving show]

(* ... *)

let message_of_line : string -> incomplete_message = function
  | "PING" -> `PING
  | "PONG" -> `PONG
  | "+OK" -> `OK
  | line when String.starts_with ~prefix:"MSG" line ->
      `MSG (Message.of_string line)
  | line when String.starts_with ~prefix:"-ERR" line ->
      `ERR (Ok_or_err.err_of_string line)
  | line when String.starts_with ~prefix:"INFO" line ->
      `INFO (Information_message.of_string line)
  | _ -> raise (Invalid_argument "incoming message line")
