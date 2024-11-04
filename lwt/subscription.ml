open Nats_client
(** Utils for handle subscriptions. *)

type t = {
  sid : Sid.t;
  subject : string;
  messages : Incoming_message.msg Lwt_stream.t;
}

let handle_stream stream f =
  Lwt.dont_wait
    (fun () -> Lwt_stream.iter_s f stream)
    (function
      (* Ignore the closed socket error. *)
      | Unix.Unix_error (Unix.EBADF, "check_descriptor", "") -> ()
      (* Otherwise, throw the exception above. *)
      | e -> raise e)

(** Asynchronous handling of incoming messages.  *)
let handle { messages; _ } f = handle_stream messages f
