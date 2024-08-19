type t = string

module Alphanumeric = struct
  let symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let length = String.length symbols
end

let create length =
  String.init length (fun _ ->
      let open Alphanumeric in
      String.unsafe_get symbols (Random.int length))
