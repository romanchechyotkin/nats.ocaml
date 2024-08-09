module Client : sig
  val default_host : string
  val default_port : int
  val lang : string

  type 'a t

  val connect : string -> int -> 'a t
  val close : 'a t -> unit Lwt.t
  val url : 'a t -> string
  val send_message : 'a t -> Messages.mtype -> string -> string Lwt.t
  val handle_message : Lwt_unix.file_descr -> string Lwt.t
end
