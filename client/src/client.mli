open Unix

module Client : sig
  val default_host : string
  val default_port : int
  val lang : string

  type 'a t = { sockaddr : sockaddr; socket : Lwt_unix.file_descr }

  val connect : string -> int -> 'a t Lwt.t
  val pub : 'a t -> string -> string option -> string -> unit Lwt.t
  val sub : 'a t -> string -> unit Lwt.t
  val close : 'a t -> unit Lwt.t
end
