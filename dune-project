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
  (alcotest :with-test)
  (ocaml
   (> 4.14))
  (dune 
   (>= 3.6))
  (lwt (
   >= 5.7))
  (lwt_ppx (
   >= 2.1))
  (yojson (
   >= 2.2)))
 (tags (nats)))
