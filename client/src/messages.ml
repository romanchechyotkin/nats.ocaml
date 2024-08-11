(* message type *)
type mtype = PING | CONNECT | PUB | HPUB | SUB | UNSUB | MSG

let string_of_mtype = function
  | PING -> "PING"
  | CONNECT -> "CONNECT" (* CONNECT {"option_name":option_value,...}␍␊ *)
  | PUB -> "PUB" (* PUB <subject> [reply-to] <#bytes>␍␊[payload]␍␊ *)
  | HPUB -> "HPUB"
  | SUB -> "SUB" (* SUB <subject> [queue group] <sid>␍␊ *)
  | UNSUB -> "UNSUB"
  | MSG -> "MSG"
