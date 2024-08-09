(* message type *)
type mtype = CONNECT

(* end messages with \r\n*)

let string_of_mtype = function
  | CONNECT ->
      "CONNECT"
