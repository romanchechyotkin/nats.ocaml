(** Subscription ID. *)

type t = string

val create : int -> t
(** [create length] Creates a string of letters and numbers of the [length]. 

    {b Warning.} Requires Random initialization to be used. *)
