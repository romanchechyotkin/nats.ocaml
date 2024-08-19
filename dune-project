(lang dune 3.16)

(name nats-client)

(generate_opam_files true)

(source
 (github romanchechyotkin/nats.ocaml))

(authors "Roman Chechyotkin")

(maintainers "Roman Chechyotkin")

(license LICENSE)

(documentation https://github.com/romanchechyotkin/nats.ocaml/blob/main/README.md)

(package
 (name nats-client)
 (synopsis "NATS client")
 (description "OCaml client for NATS, the cloud native messaging system")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))