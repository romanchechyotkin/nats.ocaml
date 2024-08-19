type t = { host : string; port : int }
(** NATS server connection settings. *)

let make ~host ~port = { host; port }
