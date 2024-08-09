module Client : sig
  val default_host : string
  val default_port : int
  val lang : string

  type 'a t

  val connect : string -> int -> 'a t
  val pub : 'a t -> string -> string -> unit
  val close : 'a t -> unit Lwt.t
end
