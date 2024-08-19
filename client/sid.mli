(** Subscription ID.

    {b Example}

    {[
        Random.self_init ();
        let sid = Sid.create 9 
    ]} *)

type t = string

val create : int -> t
(** [create length] Creates a string of letters and numbers of the [length]. 

    {b Warning.} Requires Random initialization to be used. *)
