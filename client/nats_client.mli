(** NATS Client. *)
class client : Connection.t -> object
  method init : Message.Initial.t -> string Lwt.t
  (** [init msg] send initial message request. *)

  method close : unit Lwt.t
  (** Close connection. *)

  method pub : subject:string -> ?reply_to:string -> string -> unit Lwt.t
  method receive_response : string Lwt.t
  method sub : subject:string -> ?sid:string -> unit -> unit Lwt.t
end

val make : Settings.t -> client Lwt.t
(** Make a NATS client.

    {b Example}
    {[
        let client = Nats_client.make { port = 4222; host = "127.0.0.1" } 
    ]} *)

module Message = Message
module Sid = Sid
