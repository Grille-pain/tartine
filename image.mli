open Tsdl

type t = private { surface: Sdl.surface; texture: Sdl.texture }
val load : Tartine.t -> string -> t Sdl.result
