open Unix

module Client : sig
  val default_host : string
  val default_port : int
  val lang : string

  type 'a t = { sockaddr : sockaddr; socket : Lwt_unix.file_descr }

  val connect : string -> int -> 'a t
  val pub : 'a t -> string -> string option -> string -> unit
  val sub : 'a t -> string -> unit
  val close : 'a t -> unit
end
