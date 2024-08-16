open Unix

module Client : sig
  val default_host : string
  val default_port : int
  val lang : string

  type 'a t = { sockaddr : sockaddr; socket : Lwt_unix.file_descr }

  val connect : ?host:string -> ?port:int -> unit -> 'a t Lwt.t

  val pub :
    'a t ->
    subject:string ->
    ?reply_to_subject:string option ->
    payload:string ->
    unit ->
    unit Lwt.t

  val sub : 'a t -> subject:string -> unit Lwt.t
  val close : 'a t -> unit Lwt.t
end
