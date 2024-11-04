open Nats_client
(** Utils for handle subscriptions. *)

type messages = Incoming_message.msg Lwt_stream.t
(** Alias. *)

(** Asynchronous handling of incoming messages.  *)
let handle stream f =
  Lwt.dont_wait
    (fun () -> Lwt_stream.iter_s f stream)
    (function
      (* Ignore the closed socket error. *)
      | Unix.Unix_error (Unix.EBADF, "check_descriptor", "") -> ()
      (* Otherwise, throw the exception above. *)
      | e -> raise e)
