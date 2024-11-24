(** Subscription ID.

    {b Example}

    {[
      Random.self_init ();
      let sid = Sid.create 9
    ]} *)

type t = string [@@deriving show]

module Alphanumeric = struct
  let symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let length = String.length symbols
end

(** [create length] Creates a string of letters and numbers of the [length].

    {b Warning.} Requires Random initialization to be used. *)
let create length =
  String.init length (fun _ ->
      let open Alphanumeric in
      String.unsafe_get symbols (Random.int length))
