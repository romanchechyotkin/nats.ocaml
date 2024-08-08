(* message type *)
type mtype = 
  | CONNECT

let string_of_mtype = function
| CONNECT -> "CONNECT {}"
