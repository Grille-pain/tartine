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
        path, Filename.(path ^/ "images.store")
      else Filename.dirname path, path
    in
    let h = Hashtbl.create 37 in
    (match Toml.Parser.from_filename path with
     | `Ok table ->
       TomlTypes.Table.iter
         (fun k v ->
            match v with
            | TomlTypes.TString string ->
              let k = TomlTypes.Table.Key.to_string k in
              let img_name = Filename.(dir ^/ string) in
              handle_error
                (fun s -> Printf.eprintf "%s\n%!" s)
                (Image.load img_name >>= fun img ->
                 return (Hashtbl.replace h k img))
            | _ -> Printf.eprintf "Toml: value to bad type\n%!")
         table
     | `Error (string, _) -> Printf.eprintf "Toml: %s" string);
    h

  let find k table = Hashtbl.find table k

end
