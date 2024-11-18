(lang dune 3.16)

(name nats-client)

(version 0.2)

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
   (>= 4.14))
  dune
  yojson
  ppx_yojson_conv
  (alcotest :with-test))
 (tags (nats)))

(package
 (name nats-client-lwt)
 (synopsis "NATS client based on Lwt library")
 (depends
  (ocaml
   (>= 4.14))
  lwt
  lwt_ppx
  uri
  (alcotest-lwt :with-test)))
