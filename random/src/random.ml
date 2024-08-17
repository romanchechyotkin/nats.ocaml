let symbols = "abcdefghijklmnopqrstuvwxyz"

let unique_sid () =
  Random.self_init ();

  let len = String.length symbols in
  let res = Bytes.create 10 in

  for i = 0 to 9 do
    let idx = Random.int len in
    Bytes.set res i symbols.[idx]
  done;

  Bytes.to_string res
