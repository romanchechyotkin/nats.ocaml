(lang dune 3.16)

(name nats-client)

(generate_opam_files true)

(source
 (github romanchechyotkin/nats.ocaml))

(authors "Roman Chechyotkin" "Mikhail Lopatin <dx3mod@bk.ru>")

(maintainers "Roman Chechyotkin")

(license Apache-2.0)

(package
 (name nats-client)
 (synopsis "NATS client")
 (description "OCaml client for NATS, the cloud native messaging system")
 (depends
  (ocaml
   (> 4.14))
  dune
  ; TODO: set explicit versions
  lwt
  yojson
  lwt_ppx)
 (tags (nats)))
