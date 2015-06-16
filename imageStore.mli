(** ImageStore:
   Utility module aiming at loading entire directories of images at once,
   described by an on-disk configuration file.

   An image store is described by a Toml [1] file, containing a list of toplevel
   string values (each one attached to a key). The value represents a relative
   path to the image to load, the key a name for the image, that will be used to
   recover the image (loaded into memory) from the table.

   Recognized Toml file example:
     sky = "sky.png"
     boat = "assets/boat.bmp"
     foo = "duck.jpg"

   [1] https://github.com/toml-lang/toml
*)

type t = (string, Image.t) Hashtbl.t

(** [load st path] loads an image store into memory.

    - If [path] points to a directory, then the store described by
      [path]/imagestore.toml is loaded;
    - If [path] points to a file, the file is parsed as Toml and used
      as describing a store.

    Images failing to load and invalid keys are ignored.
*)
val load : Tartine.t -> string -> t

(** Standard hashtable lookup *)
val find : string -> t -> Image.t

