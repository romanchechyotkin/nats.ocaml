(lang dune 3.16)

(name nats-client)

(version 0.1.2)

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
  ocaml
  dune
  yojson
  (alcotest :with-test))
 (tags (nats)))

(package
 (name nats-client-lwt)
 (synopsis "NATS client based on Lwt library")
 (depends
  ocaml
  lwt
  lwt_ppx
  (alcotest-lwt :with-test)))
