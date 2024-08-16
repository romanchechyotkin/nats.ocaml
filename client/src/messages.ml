(* message type *)
type mtype =
  | PING
  | CONNECT (* CONNECT {"option_name":option_value,...}␍␊ *)
  | PUB (* PUB <subject> [reply-to] <#bytes>␍␊[payload]␍␊ *)
  | HPUB
  | SUB (* SUB <subject> [queue group] <sid>␍␊ *)
  | UNSUB
  | MSG
[@@deriving of_string, to_string]
