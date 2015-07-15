open Sigs
open Tartine_utils
open Tartine_utils.Sdl_result

module Make
    (Engine: Engine_sig)
    (Image: Image_sig) =
struct
  type t = (string, Image.t) Hashtbl.t

  let load path =
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
        handle_error (fun s -> Printf.eprintf "%s\n%!" s)
          (Image.load img_name >>= fun img ->
           return (Hashtbl.replace h k img))
      with Toml.Value.To.Bad_type _ -> Printf.eprintf "Toml: value ti bad type\n%!"
    );
    h

  let find k table = Hashtbl.find table k
end
