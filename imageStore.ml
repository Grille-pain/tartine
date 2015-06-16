open Prelude
open Tartine.Operators

type t = (string, Image.t) Hashtbl.t

let load tartine path =
  let dir, path =
    if Sys.is_directory path then
      path, Filename.(path ^/ "imagestore.toml")
    else Filename.dirname path, path
  in
  let h = Hashtbl.create 37 in
  Toml.Parser.from_filename path
  |> Toml.Table.iter (fun k v ->
    try
      let img_name = Filename.(dir ^/ Toml.to_string v) in
      let k = Toml.Table.Key.to_string k in
      handle_error (fun _ -> ())
        (Image.load tartine img_name >>= fun img ->
         return (Hashtbl.replace h k img))
    with Toml.Value.To.Bad_type _ -> ()
  );
  h

let find k table = Hashtbl.find table k
