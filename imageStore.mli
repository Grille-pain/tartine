type t = (string, Image.t) Hashtbl.t

val load : Tartine.t -> string -> t
val find : string -> t -> Image.t

