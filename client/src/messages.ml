(* message type *)
type mtype = CONNECT | PUB | HPUB | SUB | UNSUB | MSG

let string_of_mtype = function
  | CONNECT -> "CONNECT" (* CONNECT {"option_name":option_value,...}␍␊ *)
  | PUB -> "PUB" (* PUB <subject> [reply-to] <#bytes>␍␊[payload]␍␊ *)
  | HPUB -> "HPUB"
  | SUB -> "SUB"
  | UNSUB -> "UNSUB"
  | MSG -> "MSG"
